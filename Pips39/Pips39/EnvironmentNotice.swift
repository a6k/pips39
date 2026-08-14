import SwiftUI
import Pips39Core

/// Zeigt, was über die Umgebung feststellbar ist — und sonst nichts.
///
/// Es gibt bewusst **keinen** grünen Gegenzustand: Ohne Verbindung erscheint diese
/// Ansicht gar nicht. Eine Entwarnung könnte die App nicht belegen (Spec 2.5).
struct EnvironmentNotice: View {

    @ObservedObject var probe: EnvironmentProbe

    var body: some View {
        if let notice = probe.notice {
            HStack(spacing: 8) {
                Image(systemName: "dot.radiowaves.left.and.right")
                Text(notice)
                    .font(.footnote)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Brand.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Brand.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    EnvironmentNotice(probe: EnvironmentProbe())
        .padding()
}
