import SwiftUI

struct OnboardingDoneStep: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("onboarding.done.title", tableName: "Onboarding")
                .font(.title3.weight(.semibold))

            Text("onboarding.done.body", tableName: "Onboarding")
                .foregroundStyle(.secondary)

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
        }
    }
}
