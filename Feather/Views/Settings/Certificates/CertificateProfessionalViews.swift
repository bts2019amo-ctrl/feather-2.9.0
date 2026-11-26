import SwiftUI

struct CertificatesOverviewCard: View {
    let certificates: [CertificatePair]

    private var revokedCount: Int { certificates.filter { $0.revoked == true }.count }
    private var activeCount: Int { certificates.count - revokedCount }

    var body: some View {
        LopfinderCard(tint: LopfinderPalette.mint) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Proteção de assinatura").font(.headline)
                    Text("Acompanhe a saúde dos seus certificados").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill").font(.title2).foregroundStyle(LopfinderPalette.mint)
            }
            Divider().padding(.vertical, 4)
            HStack {
                LopfinderMetric(title: "Total", value: "\(certificates.count)", systemImage: "seal", color: LopfinderPalette.indigo)
                Spacer()
                LopfinderMetric(title: "Ativos", value: "\(activeCount)", systemImage: "checkmark.circle.fill", color: LopfinderPalette.mint)
                if revokedCount > 0 {
                    Spacer()
                    LopfinderMetric(title: "Revogados", value: "\(revokedCount)", systemImage: "xmark.octagon.fill", color: LopfinderPalette.danger)
                }
            }
        }
    }
}

struct CertificateDiagnosticsView: View {
    let certificates: [CertificatePair]

    var body: some View {
        NavigationStack {
            List {
                Section("Status do Lopfinder") {
                    LabeledContent("Servidor", value: "Semi Local")
                    LabeledContent("Endereço", value: "Somente localhost")
                    LabeledContent("Certificados carregados", value: "\(certificates.count)")
                }
                Section("Legenda") {
                    Label("Certificado ativo", systemImage: "checkmark.circle.fill").foregroundStyle(LopfinderPalette.mint)
                    Label("Certificado revogado", systemImage: "xmark.octagon.fill").foregroundStyle(LopfinderPalette.danger)
                    Label("Verifique certificados próximos do vencimento", systemImage: "exclamationmark.triangle.fill").foregroundStyle(LopfinderPalette.warning)
                }
            }
            .navigationTitle("Diagnóstico")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
