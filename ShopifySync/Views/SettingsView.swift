import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ShopifyViewModel
    
    @State private var shopDomain: String
    @State private var accessToken: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(viewModel: ShopifyViewModel) {
        self.viewModel = viewModel
        _shopDomain = State(initialValue: viewModel.credentials.shopDomain)
        _accessToken = State(initialValue: viewModel.credentials.accessToken)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Shopify Settings")
                .font(.title)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Shop Domain")
                    .foregroundColor(.secondary)
                TextField("example.myshopify.com", text: $shopDomain)
                    .textFieldStyle(.roundedBorder)
                
                Text("Access Token")
                    .foregroundColor(.secondary)
                SecureField("Enter your access token", text: $accessToken)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal)
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Save") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .frame(width: 400, height: 300)
        .alert("Settings", isPresented: $showAlert) {
            Button("OK") {
                if !alertMessage.contains("Error") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveSettings() {
        let credentials = ShopifyCredentials(
            shopDomain: shopDomain.trimmingCharacters(in: .whitespacesAndNewlines),
            accessToken: accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        do {
            try SettingsManager.shared.saveCredentials(credentials)
            viewModel.credentials = credentials
            alertMessage = "Settings saved successfully"
        } catch {
            alertMessage = "Error saving settings: \(error.localizedDescription)"
        }
        showAlert = true
    }
} 