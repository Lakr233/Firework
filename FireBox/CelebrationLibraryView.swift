import SwiftUI

struct CelebrationLibraryView: View {
    @State private var model = ViewModel.shared
    @State private var draft = ""
    @FocusState private var isDraftFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            messageTable
            Divider()
            editor
        }
        .frame(minWidth: 440, minHeight: 300)
        .tint(.orange)
    }

    private var messageTable: some View {
        Table(model.messages, selection: $model.selectedMessageID) {
            TableColumn("") { message in
                Text(message.text)
                    .lineLimit(1)
            }
        }
        .tableStyle(.bordered)
        .tableColumnHeaders(.hidden)
        .overlay {
            if model.messages.isEmpty {
                Text("Add your first firework message")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .allowsHitTesting(false)
            }
        }
        .onDeleteCommand {
            model.removeSelectedMessage()
        }
    }

    private var editor: some View {
        HStack(spacing: 8) {
            TextField("Text or Emoji", text: $draft)
                .focused($isDraftFocused)
                .onSubmit(addMessage)
                .onChange(of: draft) { _, newValue in
                    guard newValue.count > ViewModel.maximumMessageLength else { return }
                    draft = String(newValue.prefix(ViewModel.maximumMessageLength))
                }

            if !draft.isEmpty {
                Text("\(draft.count)/\(ViewModel.maximumMessageLength)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Button(action: addMessage) {
                Label("Add", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help("Add")

            Divider()
                .frame(height: 18)

            Button(role: .destructive) {
                model.removeSelectedMessage()
            } label: {
                Label("Delete Selected Message", systemImage: "trash")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .disabled(model.selectedMessage == nil)
            .help("Delete Selected Message")

            Spacer(minLength: 8)

            Button {
                FireworkEmitter.launch()
            } label: {
                Label("Random Launch", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.messages.isEmpty)
            .keyboardShortcut(.return, modifiers: [.command])
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func addMessage() {
        guard model.addMessage(draft) else { return }
        draft = ""
        isDraftFocused = true
    }
}
