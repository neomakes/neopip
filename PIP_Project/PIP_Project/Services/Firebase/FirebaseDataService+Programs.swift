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

                    if document.exists {
                        let program = try document.data(as: Program.self)
                        print("✅ [Firebase] Fetched program successfully")
                        promise(.success(program))
                    } else {
                        print("⚠️ [Firebase] Program not found")
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
                        .order(by: "startDate", descending: true)
                        .getDocuments()

                    let enrollments = try snapshot.documents.compactMap { doc in
                        try doc.data(as: ProgramEnrollment.self)
                    }

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
