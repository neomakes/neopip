//
//  StatusView.swift
//  PIP_Project
//
//  Created by NEO on 12/19/25.
//

import SwiftUI

struct StatusView: View {
    @Environment(\.modelContext) private var modelContext
    @Query("status") private var status: [Status]

    var body: some View {
        NavigationView {
            List {
                ForEach(status) { status in
                    NavigationLink {
                        Text("Status at \(status.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(status.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteStatus)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addStatus) {
                        Label("Add Status", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func addStatus() {
        withAnimation {
            let newStatus = Status(timestamp: Date())
            modelContext.insert(newStatus)
        }
    }

    private func deleteStatus(offsets: Index
