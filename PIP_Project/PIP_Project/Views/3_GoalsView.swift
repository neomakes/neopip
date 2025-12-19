//
//  GoalsView.swift
//  PIP_Project
//
//  Created by NEO on 12/19/25.
//

import SwiftUI

struct GoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query("goals") private var goals: [Goal]

    var body: some View {
        NavigationView {
            List {
                ForEach(goals) { goal in
                    NavigationLink {
                        Text("Goal at \(goal.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(goal.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteGoals)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addGoal) {
                        Label("Add Goal", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func addGoal() {
        withAnimation {
            let newGoal = Goal(timestamp: Date())
            modelContext.insert(newGoal)
        }
    }

    private func deleteGoals(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(goals[index])
            }
        }
    }
}
