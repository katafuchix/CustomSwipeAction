//
//  ContentView.swift
//  CustomSwipeAction
//
//  Created by cano on 2025/03/20.
//

import SwiftUI

struct Profile: Identifiable, Hashable {
    var id = UUID().uuidString
    var userName: String
    var profilePicture: String
    var lastMsg: String
}

/// Sample Profile Data
var profiles = [
    Profile(userName: "iJustine", profilePicture: "Pic1", lastMsg: "Hi Kavsoft !!!"),
    Profile(userName: "Jenna Ezarik", profilePicture: "Pic2", lastMsg: "Nothing!"),
    Profile(userName: "Emily", profilePicture: "Pic3", lastMsg: "Binge Watching"),
    Profile(userName: "Juliet", profilePicture: "Pic4", lastMsg: "404 Page not Found"),
    Profile(userName: "Rebeca", profilePicture: "Pic5", lastMsg: "Do not Disturb.")
]

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Usage")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                    
                    Text(
                        """
                        .swipeActions {
                            Action {
                                
                            }...
                        }
                        """
                    )
                    .font(.callout)
                    .monospaced()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(15)
                    .background(.background, in: .rect(cornerRadius: 10))
                    
                    Text("Messages")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .padding(.top, 15)
                    
                    ForEach(profiles) { profile in
                        HStack(spacing: 12) {
                            Image(profile.profilePicture)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 45, height: 45)
                                .clipShape(.circle)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.userName)
                                    .font(.callout)
                                    .foregroundStyle(Color.primary)
                                
                                Text(profile.lastMsg)
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                            
                            Spacer(minLength: 0)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 15)
                        .background(.background, in: .rect(cornerRadius: 10))
                        .swipeActions {
                            Action(symbolImage: "square.and.arrow.up.fill", tint: .white, background: .blue) { resetPosition in
                                resetPosition.toggle()
                            }
                            
                            Action(symbolImage: "square.and.arrow.down.fill", tint: .white, background: .purple) { resetPosition in
                                
                            }
                            
                            Action(symbolImage: "trash.fill", tint: .white, background: .red) { resetPosition in
                                
                            }
                        }
                    }
                }
                .padding(15)
            }
            .navigationTitle("Custom Swipe Actions")
            .background(.gray.opacity(0.1))
        }
    }
}

#Preview {
    ContentView()
}
