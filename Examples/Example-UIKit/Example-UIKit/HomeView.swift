import SwiftUI

struct HomeView: View {
    let viewModel: ItemViewModel
    var body: some View {
        VStack(spacing: 20) {
            LineItemRow(
                title: "Items (\(viewModel.itemCount))",
                value: viewModel.itemTotal)
            LineItemRow(
                title: "Shipping & Handling",
                value: viewModel.shipping)
            LineItemRow(
                title: "Estimated tax",
                value: viewModel.estimatedTax)
            LineItemRow(
                title: "Order Total",
                value: viewModel.total)
            .font(.title)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    HomeView(viewModel: ItemViewModel())
}
