//
//  TaskListView.swift
//  SwiftUIApp
//
//  Created by Amr Aboelela on 12/19/23.
//

// Implement a SwiftUI View with Realm Data Integration

import SwiftUI
import RealmSwift

class TaskObject: Object, Identifiable {
    @Persisted @objc dynamic var id = UUID().uuidString
    @Persisted var title: String = ""
    @Persisted var isCompleted: Bool = false
}

struct TaskListView: View {
    @ObservedResults(TaskObject.self) var tasks

    var body: some View {
        NavigationView {
            List(tasks) { task in
                Text(task.id)
                    .foregroundColor(task.isCompleted ? .green : .red)
                Text(task.title)
                    .foregroundColor(task.isCompleted ? .green : .red)
            }
            .navigationBarTitle("TaskObject List")
        }
        .task {
            // Fill the tasks list with sample data on view appearance
            addSampleData()
        }
    }
    
    private func addSampleData() {
        do {
            // Get the Realm instance
            let realm = try Realm()

            // Check if sample data is already added
            guard realm.objects(TaskObject.self).isEmpty else {
                return
            }

            // Create and persist sample tasks
            try realm.write {
                let task1 = TaskObject()
                task1.title = "Complete assignment"
                realm.add(task1)

                let task2 = TaskObject()
                task2.title = "Read a book"
                realm.add(task2)

                let task3 = TaskObject()
                task3.title = "Go for a run"
                task3.isCompleted = true
                realm.add(task3)
            }
        } catch {
            print("Error adding sample data: \(error)")
        }
    }
}

#Preview {
    TaskListView()
}
