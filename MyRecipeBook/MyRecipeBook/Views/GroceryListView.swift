import SwiftUI
import SwiftData

struct GroceryListsView: View {
    @Query(sort: \GroceryList.createdAt, order: .reverse) private var lists: [GroceryList]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingNewListSheet = false
    @State private var newListName = ""
    
    var body: some View {
        Group {
            if lists.isEmpty {
                ContentUnavailableView("No Grocery Lists",
                                     systemImage: "cart",
                                     description: Text("Create a list with the + button"))
            } else {
                List {
                    ForEach(lists) { list in
                        NavigationLink(destination: GroceryListDetailView(list: list)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(list.name)
                                    .font(.headline)
                                Text("\(list.items.count) item(s) · \(list.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteLists)
                }
            }
        }
        .navigationTitle("Grocery Lists")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewListSheet = true }) {
                    Label("New List", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewListSheet) {
            NavigationStack {
                Form {
                    TextField("List Name", text: $newListName)
                }
                .navigationTitle("New List")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            newListName = ""
                            showingNewListSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            createList()
                            showingNewListSheet = false
                        }
                        .disabled(newListName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }
    
    private func createList() {
        let name = newListName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let list = GroceryList(name: name)
        modelContext.insert(list)
        newListName = ""
    }
    
    private func deleteLists(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(lists[index])
        }
    }
}

struct GroceryListDetailView: View {
    @Bindable var list: GroceryList
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteAlert = false
    
    private var sortedItems: [GroceryItem] {
        list.items.sorted { lhs, rhs in
            if lhs.isChecked != rhs.isChecked {
                return !lhs.isChecked && rhs.isChecked
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
    
    var body: some View {
        List {
            ForEach(sortedItems) { item in
                HStack(alignment: .top, spacing: 12) {
                    Button(action: { item.isChecked.toggle() }) {
                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isChecked ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(itemText(item))
                            .strikethrough(item.isChecked)
                            .foregroundStyle(item.isChecked ? .secondary : .primary)
                        if let source = item.recipeSource {
                            Text(source)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Clear Checked") { clearChecked() }
                    Button("Delete List", role: .destructive) { showingDeleteAlert = true }
                } label: {
                    Label("Options", systemImage: "ellipsis")
                }
            }
        }
        .alert("Delete List?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(list)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func itemText(_ item: GroceryItem) -> String {
        if let amount = item.amount {
            let unit = item.unit ?? ""
            return "\(AmountFormatter.string(amount)) \(unit) \(item.name)".trimmingCharacters(in: .whitespaces)
        }
        return item.name
    }
    
    private func deleteItems(at offsets: IndexSet) {
        let items = sortedItems
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
    
    private func clearChecked() {
        for item in list.items where item.isChecked {
            modelContext.delete(item)
        }
    }
}

struct AddToGroceryListSheet: View {
    let recipe: Recipe
    let servingsMultiplier: Double
    
    @Query(sort: \GroceryList.createdAt, order: .reverse) private var lists: [GroceryList]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var newListName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                if !lists.isEmpty {
                    Section("Existing Lists") {
                        ForEach(lists) { list in
                            Button(action: { addToList(list) }) {
                                HStack {
                                    Text(list.name)
                                    Spacer()
                                    Text("\(list.items.count) item(s)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Section("New List") {
                    TextField("List Name", text: $newListName)
                    Button("New List") { addToNewList() }
                        .disabled(newListName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Add to Grocery List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func addToList(_ list: GroceryList) {
        GroceryMerger.add(ingredients: recipe.ingredients,
                          scaledBy: servingsMultiplier,
                          to: list,
                          source: recipe.title,
                          in: modelContext)
        dismiss()
    }
    
    private func addToNewList() {
        let name = newListName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let list = GroceryList(name: name)
        modelContext.insert(list)
        addToList(list)
    }
}
