//
//  Lecture2QuizTabView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 3/29/25.
//

import SwiftUI

struct TableView: View {
    @State var selectedTab: String = "Home"

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tag("Home")

                FolderListView()
                    .tag("Class")

                QuizMainView()
                    .tag("Quiz")

                OtherView()
                    .tag("Other")
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack {
                tabButton(title: "Home", defaultImage: "house", selectedImage: "house.fill")
                tabButton(title: "Class", defaultImage: "folder", selectedImage: "folder.fill")
                tabButton(title: "Quiz", defaultImage: "questionmark.text.page", selectedImage: "questionmark.text.page.fill")
                tabButton(title: "Other", defaultImage: "person", selectedImage: "person.fill")
            }
            .padding()
            .background(Color.white)
        }.navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true) 
    }

    @ViewBuilder
    private func tabButton(title: String, defaultImage: String, selectedImage: String) -> some View {
        Button {
            selectedTab = title
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == title ? selectedImage : defaultImage)
                    .frame(width: 24, height: 24)
                    .foregroundColor(selectedTab == title ? Color.blue : .gray)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(selectedTab == title ? Color.blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    NavigationStack {
        TableView()
    }
}
