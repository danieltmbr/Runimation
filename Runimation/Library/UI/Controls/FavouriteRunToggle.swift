import SwiftUI

struct FavouriteRunToggle: View {

    @Binding
    var isFavourite: Bool
    
    var body: some View {
        Button {} label: {
            if isFavourite {
                Label("Unfavourite", systemImage: "heart.slash")
            } else {
                Label("Favourite", systemImage: "heart")
            }
        }
        .disabled(true)
    }
}

#Preview {
    FavouriteRunToggle(isFavourite: .constant(false))
}
