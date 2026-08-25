import SwiftUI

/// Eine Onboarding-Seite: Überschrift, scrollbarer Inhalt, Platz für die Fußleiste.
///
/// `title` ist ein `LocalizedStringKey` und kein `String`: `Text(einString)`
/// lokalisiert **nicht** — nur ein Literal oder ein `LocalizedStringKey` geht durch die
/// Übersetzungstabelle. Das ist in diesem Projekt schon viermal passiert.
struct OnboardingPage<Content: View>: View {

    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.largeTitle.bold())
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .padding(.bottom, 28)
        }
    }
}
