import CoreGraphics

/// Posts a system keyboard shortcut without any mouse button ownership.
public protocol ShortcutInputSink: SyntheticInputSink {
    func tryPostShortcut(_ shortcut: SpaceShortcut) -> SyntheticInputResult
}
