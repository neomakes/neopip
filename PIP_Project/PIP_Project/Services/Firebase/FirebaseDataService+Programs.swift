//
//  FirebaseDataService+Programs.swift
//  PIP_Project
//
//  Created by Gemini on 2026/01/10.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

// MARK: - Programs & Enrollments
extension FirebaseDataService {
    
    // MARK: - Programs
    func fetchPrograms() -> AnyPublisher<[Program], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    print("📥 [Firebase] Fetching all programs")

                    let snapshot = try await self.db
                        .collection("programs")
                        .order(by: "popularity", descending: true)
                        .getDocuments()

                    let programs = try snapshot.documents.compactMap { doc in
                        try doc.data(as: Program.self)
                    }

                    print("✅ [Firebase] Fetched \(programs.count) programs")
                    promise(.success(programs))
                } catch {
                    let ns = error as NSError
                    print("❌ [Firebase] Error fetching programs: \(ns.localizedDescription)")
                    
                    if ns.domain == "FIRFirestoreErrorDomain" && ns.code == 7 {
                        print("⚠️ [Firebase] Permission denied. Returning empty.")
                        promise(.success([]))
                    } else {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchProgram(id: UUID) -> AnyPublisher<Program?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    print("📥 [Firebase] Fetching program with id: \(id)")

                    let document = try await self.db
                        .collection("programs")
                        .document(id.uuidString)
                        .getDocument()

                    if document.exists, var program = try? document.data(as: Program.self) {
                         // Fetch sub-collection 'progress' for stories
                         let storiesSnapshot = try await self.db
                             .collection("programs")
                             .document(id.uuidString)
                             .collection("progress")
                             .getDocuments()
                         
                         let stories = try storiesSnapshot.documents.compactMap { doc in
                             try doc.data(as: ProgramStory.self)
                         }
                         
                         program.stories = stories.sorted {
                             // Sort logic? ProgramStory doesn't have explicit order field, using title or id or createdAt?
                             // Mock data has 'Day 1', 'Day 2' etc. createdAt is safer if generated sequentially, or parse title.
                             // For now, let's sort by createdAt.
                             $0.createdAt < $1.createdAt
                         }
                        
                        print("✅ [Firebase] Fetched program with \(stories.count) stories")
                        promise(.success(program))
                    } else {
                        print("⚠️ [Firebase] Program not found or decode failed")
                        promise(.success(nil))
                    }
                } catch {
                    print("❌ [Firebase] Error fetching program: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchRecommendedPrograms(for userId: String) -> AnyPublisher<[Program], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    print("📥 [Firebase] Fetching recommended programs for user: \(userId)")

                    let snapshot = try await self.db
                        .collection("programs")
                        .whereField("isRecommended", isEqualTo: true)
                        .order(by: "popularity", descending: true)
                        .limit(to: 10)
                        .getDocuments()

                    let programs = try snapshot.documents.compactMap { doc in
                        try doc.data(as: Program.self)
                    }

                    print("✅ [Firebase] Fetched \(programs.count) recommended programs")
                    promise(.success(programs))
                } catch {
                    print("❌ [Firebase] Error fetching recommended programs: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    func fetchProgramMissions(for programId: UUID) -> AnyPublisher<[ProgramMission], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    print("📥 [Firebase] Fetching missions for program: \(programId)")

                    let snapshot = try await self.db
                        .collection("programs")
                        .document(programId.uuidString)
                        .collection("missions")
                        .order(by: "day", descending: false)
                        .getDocuments()

                    let missions = try snapshot.documents.compactMap { doc in
                        try doc.data(as: ProgramMission.self)
                    }

                    print("✅ [Firebase] Fetched \(missions.count) missions")
                    promise(.success(missions))
                } catch {
                    print("❌ [Firebase] Error fetching missions: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchProgramMetrics(for programId: UUID) -> AnyPublisher<[ProgramSuccessMetric], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    print("📥 [Firebase] Fetching metrics for program: \(programId)")

                    let snapshot = try await self.db
                        .collection("programs")
                        .document(programId.uuidString)
                        .collection("metrics")
                        .getDocuments()

                    let metrics = try snapshot.documents.compactMap { doc in
                        try doc.data(as: ProgramSuccessMetric.self)
                    }

                    print("✅ [Firebase] Fetched \(metrics.count) metrics")
                    promise(.success(metrics))
                } catch {
                    print("❌ [Firebase] Error fetching metrics: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveProgramMetric(programId: UUID, metric: ProgramSuccessMetric) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    print("💾 [Firebase] Saving metric: \(metric.metricName) for program: \(programId)")

                    try await self.db
                        .collection("programs")
                        .document(programId.uuidString)
                        .collection("metrics")
                        .document(metric.id.uuidString)
                        .setData(from: metric)

                    print("✅ [Firebase] Saved metric successfully")
                    promise(.success(()))
                } catch {
                    print("❌ [Firebase] Error saving metric: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func saveProgramMission(programId: UUID, mission: ProgramMission) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    print("💾 [Firebase] Saving mission: \(mission.title) (Day \(mission.day)) for program: \(programId)")

                    try await self.db
                        .collection("programs")
                        .document(programId.uuidString)
                        .collection("missions")
                        .document(mission.id.uuidString)
                        .setData(from: mission)

                    print("✅ [Firebase] Saved mission successfully")
                    promise(.success(()))
                } catch {
                    print("❌ [Firebase] Error saving mission: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func saveProgram(_ program: Program) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    print("💾 [Firebase] Saving program: \(program.name) (\(program.id))")

                    try await self.db
                        .collection("programs")
                        .document(program.id.uuidString)
                        .setData(from: program)

                    print("✅ [Firebase] Saved program successfully")
                    promise(.success(()))
                } catch {
                    print("❌ [Firebase] Error saving program: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveProgramStory(programId: UUID, story: InsightStory) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    print("💾 [Firebase] Saving story: \(story.id) for program: \(programId)")

                    try await self.db
                        .collection("programs")
                        .document(programId.uuidString)
                        .collection("progress")
                        .document(story.id)
                        .setData(from: story)

                    print("✅ [Firebase] Saved story successfully")
                    promise(.success(()))
                } catch {
                    print("❌ [Firebase] Error saving story: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Program Enrollments
    func createProgramEnrollment(_ enrollment: ProgramEnrollment) -> AnyPublisher<ProgramEnrollment, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    var updatedEnrollment = enrollment
                    updatedEnrollment.accountId = accountId
                    updatedEnrollment.updatedAt = Date()

                    print("💾 [Firebase] Creating program enrollment: \(updatedEnrollment.id)")

                    try self.db
                        .collection("users")
                        .document(accountId)
                        .collection("program_enrollments")
                        .document(updatedEnrollment.id.uuidString)
                        .setData(from: updatedEnrollment)

                    print("✅ [Firebase] Created program enrollment successfully")
                    promise(.success(updatedEnrollment))
                } catch {
                    print("❌ [Firebase] Error creating program enrollment: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchProgramEnrollments() -> AnyPublisher<[ProgramEnrollment], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    print("📥 [Firebase] Fetching program enrollments for user: \(accountId)")

                    let snapshot = try await self.db
                        .collection("users")
                        .document(accountId)
                        .collection("program_enrollments")
                        .whereField("status", isEqualTo: "active")
                        // .order(by: "startDate", descending: true) // Removed to avoid Composite Index requirement
                        .getDocuments()

                    let enrollments = try snapshot.documents.compactMap { doc in
                        try doc.data(as: ProgramEnrollment.self)
                    }.sorted { $0.startDate > $1.startDate } // Sort client-side instead

                    print("✅ [Firebase] Fetched \(enrollments.count) program enrollments")
                    promise(.success(enrollments))
                } catch {
                    print("❌ [Firebase] Error fetching program enrollments: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchProgramEnrollment(id: UUID) -> AnyPublisher<ProgramEnrollment?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    print("📥 [Firebase] Fetching program enrollment: \(id)")

                    let snapshot = try await self.db
                        .collection("users")
                        .document(accountId)
                        .collection("program_enrollments")
                        .document(id.uuidString)
                        .getDocument()

                    guard snapshot.exists else {
                        print("⚠️ [Firebase] Program enrollment not found: \(id)")
                        promise(.success(nil))
                        return
                    }

                    let enrollment = try snapshot.data(as: ProgramEnrollment.self)
                    print("✅ [Firebase] Fetched program enrollment: \(id)")
                    promise(.success(enrollment))
                } catch {
                    print("❌ [Firebase] Error fetching program enrollment: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func updateProgramEnrollment(_ enrollment: ProgramEnrollment) -> AnyPublisher<ProgramEnrollment, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    var updatedEnrollment = enrollment
                    updatedEnrollment.updatedAt = Date()

                    print("💾 [Firebase] Updating program enrollment: \(updatedEnrollment.id)")

                    try self.db
                        .collection("users")
                        .document(accountId)
                        .collection("program_enrollments")
                        .document(updatedEnrollment.id.uuidString)
                        .setData(from: updatedEnrollment)

                    print("✅ [Firebase] Updated program enrollment successfully")
                    promise(.success(updatedEnrollment))
                } catch {
                    print("❌ [Firebase] Error updating program enrollment: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

}
