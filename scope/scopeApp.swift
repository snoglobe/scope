//
//  scopeApp.swift
//  scope
//
//  Created by bun on 11/18/24.
//

import SwiftUI
import HealthKit
import Speech

@main
struct ScopeApp: App {
    @StateObject private var dataManager = HealthDataManager()
    @StateObject private var aiManager = AIManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var speechManager = SpeechManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(aiManager)
                .environmentObject(healthKitManager)
                .environmentObject(speechManager)
        }
    }
}

class HealthDataManager: ObservableObject {
    static let instance = HealthDataManager()
    
    @Published var notes: [HealthNote] = []
    @Published var quickLogTypes: [QuickLogType] = []
    
    private let storageManager = StorageManager()
    
    init() {
        loadData()
        setupDefaultQuickLogTypes()
    }
    
    func addNote(_ note: HealthNote) {
        notes.append(note)
        saveData()
    }
    
    private func loadData() {
        notes = storageManager.load("healthNotes.json") ?? []
        quickLogTypes = storageManager.load("quickLogTypes.json") ?? []
    }
    
    func saveData() {
        storageManager.save(notes, to: "healthNotes.json")
        storageManager.save(quickLogTypes, to: "quickLogTypes.json")
    }
    
    func importData(notes: [HealthNote], quickLogTypes: [QuickLogType]) {
        self.notes = notes
        self.quickLogTypes = quickLogTypes
        saveData()
    }
    
    func deleteNotes(before date: Date) {
        notes.removeAll { $0.timestamp < date }
        saveData()
    }
    
    private func setupDefaultQuickLogTypes() {
        if quickLogTypes.isEmpty {
            quickLogTypes = [
                QuickLogType(id: UUID(), name: "Pain Level", unit: "1-10", icon: "flame.fill", color: "#ff5e6c"),
                QuickLogType(id: UUID(), name: "Mood", unit: "1-5", icon: "face.smiling", color: "#ffcf5e"),
                QuickLogType(id: UUID(), name: "Energy", unit: "1-5", icon: "bolt.fill", color: "#76ff5e"),
                QuickLogType(id: UUID(), name: "Sleep Quality", unit: "1-5", icon: "moon.fill", color: "#5e5eff")
            ]
            saveData()
        }
    }
}

class AIManager: ObservableObject {
    static let shared = AIManager()
    private var client: Anthropic?
    @Published var isProcessing = false
    @AppStorage("aiModel") private var selectedModel = "claude-3-5-sonnet-latest"
    
    init() {
        setupAnthropicClient()
    }
    
    private func setupAnthropicClient() {
        if let apiKey = KeychainManager.shared.getAnthropicAPIKey() {
            client = Anthropic(apiKey: apiKey)
        }
    }
    
    func chat(_ message: Message) async throws -> String {
        guard let client = client else {
            print("Error: Anthropic client not initialized.")
            throw AIError.clientNotInitialized
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let response = try await client.messages!.create(
            model: selectedModel,
            messages: [message],
            system: "You are a health analysis assistant. Analyze the provided health data and provide structured insights."
        )
        
        return response.content.first?.text ?? "No response generated"
    }
    
    func analyzeHealthNote(_ note: HealthNote) async throws -> HealthNote.AnalysisResults {
        guard let client = client else {
            print("Error: Anthropic client not initialized.")
            throw AIError.clientNotInitialized
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let prompt = buildAnalysisPrompt(for: note)
        print("getting")
        let response = try await client.messages!.create(
            model: selectedModel,
            messages: [Message(
                role: "user",
                content: [[
                    "type": "text",
                    "text": prompt
                ]]
            )],
            system: "You are a health analysis assistant. Analyze the provided health data and provide structured insights."
        )
        print("parsing")
        return try parseAnalysisResponse(response)
    }
    
    private func buildAnalysisPrompt(for note: HealthNote) -> String {
        let allNotes = HealthDataManager.instance.notes
        
        return """
        Analyze this health data and respond ONLY with a JSON object. Do not include any other text.
        
        Input Data:
        {
            "current_note": {
                "timestamp": "\(note.timestamp.ISO8601Format())",
                "content": "\(note.content)",
                "quick_logs": [
                    \(note.quickLogData.map { "{ \"type\": \"\($0.type)\", \"value\": \($0.value), \"unit\": \"\($0.unit ?? "")\" }" }.joined(separator: ",\n"))
                ],
                "tags": [\(note.tags.map { "\"\($0)\"" }.joined(separator: ", "))]
            },
            "historical_data": {
                "total_notes": \(allNotes.count),
                "previous_notes": [
                    \(allNotes.prefix(10).map { note -> String in
                        """
                        {
                            "timestamp": "\(note.timestamp.ISO8601Format())",
                            "content": "\(note.content)",
                            "quick_logs": [
                                \(note.quickLogData.map { "{ \"type\": \"\($0.type)\", \"value\": \($0.value), \"unit\": \"\($0.unit ?? "")\" }" }.joined(separator: ",\n"))
                            ],
                            "tags": [\(note.tags.map { "\"\($0)\"" }.joined(separator: ", "))]
                        }
                        """
                    }.joined(separator: ",\n"))
                ]
            }
        }

        Expected Response Format:
        {
            "structuredData": {
                "mood": "positive/negative/neutral",
                "symptoms": ["symptom1", "symptom2"],
                "severity": "mild/moderate/severe",
                "triggers": ["trigger1", "trigger2"]
            },
            "categories": ["category1", "category2"],
            "insights": [
                "Clear observation about patterns or correlations",
                "Important health-related findings",
                "Suggestions based on the data"
            ]
        }
        """
    }
    
    private func parseAnalysisResponse(_ response: MessageResponse) throws -> HealthNote.AnalysisResults {
        print("Received AI response: \(response.content.first?.text ?? "")")
        
        // Get only the JSON part of the response
        let content = response.content.first?.text ?? ""
        guard let jsonStart = content.firstIndex(of: "{"),
              let jsonEnd = content.lastIndex(of: "}"),
              let data = String(content[jsonStart...jsonEnd]).data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawStructuredData = json["structuredData"] as? [String: Any],
              let categories = json["categories"] as? [String],
              let insights = json["insights"] as? [String] else {
            throw AIError.analysisFailure("Failed to parse AI response")
        }
        
        // Convert structured data to string values
        let structuredData = rawStructuredData.mapValues { value -> String in
            if let stringValue = value as? String {
                return stringValue
            } else if let arrayValue = value as? [String] {
                return arrayValue.joined(separator: ", ")
            } else {
                return String(describing: value)
            }
        }
        
        return HealthNote.AnalysisResults(
            structuredData: structuredData,
            categories: categories,
            insights: insights
        )
    }
}

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let relevantTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    ]
    
    private func preferredUnit(for type: HKQuantityType) -> HKUnit {
        switch type.identifier {
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return HKUnit.count().unitDivided(by: .minute())
        case HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
             HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue:
            return HKUnit.millimeterOfMercury()
        case HKQuantityTypeIdentifier.bodyTemperature.rawValue:
            return HKUnit.degreeCelsius()
        case HKQuantityTypeIdentifier.respiratoryRate.rawValue:
            return HKUnit.count().unitDivided(by: .minute())
        case HKQuantityTypeIdentifier.oxygenSaturation.rawValue:
            return HKUnit.percent()
        default:
            return HKUnit.count()
        }
    }
    
    func requestAuthorization() {
        healthStore.requestAuthorization(toShare: [], read: relevantTypes) { success, error in
            if let error = error {
                print("HealthKit authorization failed: \(error)")
            }
        }
    }
    
    func fetchRecentData(completion: @escaping ([HealthNote.HealthKitDataPoint]) -> Void) {
        var dataPoints: [HealthNote.HealthKitDataPoint] = []
        let group = DispatchGroup()
        
        for type in relevantTypes {
            group.enter()
            
            guard let quantityType = type as? HKQuantityType else {
                group.leave()
                continue
            }
            
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: HKQuery.predicateForSamples(
                    withStart: Calendar.current.date(byAdding: .hour, value: -24, to: Date()),
                    end: Date(),
                    options: .strictStartDate
                ),
                limit: 100,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                defer { group.leave() }
                
                guard let samples = samples as? [HKQuantitySample], error == nil else { return }
                
                let unit = self.preferredUnit(for: quantityType)
                
                for sample in samples {
                    let dataPoint = HealthNote.HealthKitDataPoint(
                        id: UUID().uuidString,
                        type: sample.quantityType.identifier,
                        value: sample.quantity.doubleValue(for: unit),
                        unit: unit.unitString,
                        timestamp: sample.startDate
                    )
                    dataPoints.append(dataPoint)
                }
            }
            
            healthStore.execute(query)
        }
        
        group.notify(queue: .main) {
            completion(dataPoints)
        }
    }
}

class SpeechManager: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isRecording = false
    @Published var transcribedText = ""
    
    func startRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isRecording = false
    }
}

class StorageManager {
    let fileManager = FileManager.default
    
    func save<T: Encodable>(_ data: T, to filename: String) {
        do {
            let documentsURL = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let fileURL = documentsURL.appendingPathComponent(filename)
            let encodedData = try JSONEncoder().encode(data)
            try encodedData.write(to: fileURL)
        } catch {
            print("Failed to save data: \(error)")
        }
    }
    
    func load<T: Decodable>(_ filename: String) -> T? {
        do {
            let documentsURL = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            let fileURL = documentsURL.appendingPathComponent(filename)
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Failed to load data: \(error)")
            return nil
        }
    }
}

class KeychainManager {
    static let shared = KeychainManager()
    
    func getAnthropicAPIKey() -> String? {
        // Implementation would use Keychain Services API to securely retrieve the API key
        // For development purposes, return a placeholder
        return "..."
    }
}

enum AIError: Error {
    case clientNotInitialized
    case analysisFailure(String)
}
