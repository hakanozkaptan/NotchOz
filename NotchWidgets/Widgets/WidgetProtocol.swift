import SwiftUI

protocol WidgetProtocol: View {
    var widgetId: String { get }
    var compact: Bool { get }
}
