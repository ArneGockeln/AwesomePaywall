struct DiscountBadgeView: View {
        let discount: Int
        let backgroundColor: Color

        var body: some View {
            Text("SAVE \(discount)%")
                .foregroundStyle(Color.black)
                .font(.caption.bold())
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundStyle(backgroundColor)
                }
        }
    }