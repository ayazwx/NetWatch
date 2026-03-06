import SwiftUI

struct ActionsView: View {
    @ObservedObject var actionManager: ActionManager
    @State private var showAddSheet = false
    @State private var feedback: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 2) {
                    let predefined = actionManager.actions.filter { $0.isPredefined }
                    let custom = actionManager.actions.filter { !$0.isPredefined }

                    if !predefined.isEmpty {
                        sectionHeader("System")
                        ForEach(predefined) { action in
                            actionRow(action)
                        }
                    }

                    if !custom.isEmpty {
                        sectionHeader("Custom Actions")
                        ForEach(custom) { action in
                            actionRow(action, deletable: true)
                        }
                    }
                }
                .padding(.horizontal)
            }

            if let feedback {
                Text(feedback)
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.green.opacity(0.1))
            }

            Divider()

            Button {
                showAddSheet = true
            } label: {
                Label("Add New Action", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.cyan)
            .padding(.horizontal)
        }
        .sheet(isPresented: $showAddSheet) {
            AddActionSheet(actionManager: actionManager, isPresented: $showAddSheet)
        }
        .onChange(of: actionManager.lastResult) {
            feedback = actionManager.lastResult
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                feedback = nil
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.caption2, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .padding(.bottom, 2)
    }

    private func actionRow(_ action: QuickAction, deletable: Bool = false) -> some View {
        HStack {
            Image(systemName: action.icon)
                .frame(width: 20)
                .foregroundStyle(.cyan)

            Text(action.name)
                .font(.system(.caption, weight: .medium))

            Spacer()

            if deletable {
                Button {
                    actionManager.deleteAction(action)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            if action.isToggle {
                Toggle("", isOn: Binding(
                    get: { action.isEnabled },
                    set: { _ in actionManager.runAction(action) }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
            } else {
                Button {
                    actionManager.runAction(action)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.cyan)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

struct AddActionSheet: View {
    @ObservedObject var actionManager: ActionManager
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var icon = "terminal.fill"
    @State private var command = ""
    @State private var isToggle = false
    @State private var toggleOffCommand = ""

    private let icons = [
        "terminal.fill", "gear", "network", "wifi.slash",
        "stop.fill", "pause.fill", "xmark.circle.fill",
        "bolt.fill", "hammer.fill", "wrench.fill"
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("New Action")
                .font(.headline)

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("Icon:")
                    .font(.caption)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(icons, id: \.self) { ic in
                            Button {
                                icon = ic
                            } label: {
                                Image(systemName: ic)
                                    .padding(6)
                                    .background(icon == ic ? Color.cyan.opacity(0.3) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            TextField("Shell Command", text: $command)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            Toggle("Toggle (On/Off)", isOn: $isToggle)
                .font(.caption)

            if isToggle {
                TextField("Off Command", text: $toggleOffCommand)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            HStack {
                Button("Cancel") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add") {
                    guard !name.isEmpty, !command.isEmpty else { return }
                    actionManager.addCustomAction(
                        name: name,
                        icon: icon,
                        command: command,
                        isToggle: isToggle,
                        toggleOffCommand: isToggle ? toggleOffCommand : nil
                    )
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || command.isEmpty)
            }
        }
        .padding()
        .frame(width: 380)
    }
}
