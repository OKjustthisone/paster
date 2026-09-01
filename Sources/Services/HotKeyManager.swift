import AppKit
import Carbon
import Combine
import Foundation

public enum GlobalHotKeyOption: String, CaseIterable, Identifiable {
    case cmdShiftV = "cmd_shift_v"
    case optV = "opt_v"
    case cmdOptV = "cmd_opt_v"
    case ctrlOptV = "ctrl_opt_v"
    case disabled = "disabled"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cmdShiftV: return "⌘ ⇧ V  (推荐)"
        case .optV: return "⌥ V"
        case .cmdOptV: return "⌘ ⌥ V"
        case .ctrlOptV: return "⌃ ⌥ V"
        case .disabled: return "已关闭"
        }
    }

    public var carbonModifiers: UInt32 {
        switch self {
        case .cmdShiftV:
            return UInt32(cmdKey | shiftKey)
        case .optV:
            return UInt32(optionKey)
        case .cmdOptV:
            return UInt32(cmdKey | optionKey)
        case .ctrlOptV:
            return UInt32(controlKey | optionKey)
        case .disabled:
            return 0
        }
    }

    public var carbonKeyCode: UInt32 {
        // 'V' 键在 macOS 上的虚拟键码 (kVK_ANSI_V = 0x09)
        return 0x09
    }
}

public final class HotKeyManager: ObservableObject {
    public static let shared = HotKeyManager()

    @Published public var currentOption: GlobalHotKeyOption = .cmdShiftV

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    public var onHotKeyPressed: (() -> Void)?

    private init() {
        let savedRaw = UserDefaults.standard.string(forKey: "globalHotKeyOption") ?? GlobalHotKeyOption.cmdShiftV.rawValue
        self.currentOption = GlobalHotKeyOption(rawValue: savedRaw) ?? .cmdShiftV
    }

    public func setup() {
        installCarbonEventHandler()
        register(option: currentOption)
    }

    public func updateHotKey(to option: GlobalHotKeyOption) {
        self.currentOption = option
        UserDefaults.standard.set(option.rawValue, forKey: "globalHotKeyOption")
        register(option: option)
    }

    private func register(option: GlobalHotKeyOption) {
        unregister()

        guard option != .disabled else { return }

        let hotKeyID = EventHotKeyID(signature: OSType(0x50535452), id: 1) // 'PSTR', 1
        let status = RegisterEventHotKey(
            option.carbonKeyCode,
            option.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            print("[HotKeyManager] Failed to register hotkey: \(status)")
        }
    }

    private func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    private func installCarbonEventHandler() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerBlock: EventHandlerUPP = { _, _, _ -> OSStatus in
            DispatchQueue.main.async {
                HotKeyManager.shared.onHotKeyPressed?()
            }
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerBlock,
            1,
            &eventType,
            nil,
            &eventHandler
        )
    }

    deinit {
        unregister()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }
}
