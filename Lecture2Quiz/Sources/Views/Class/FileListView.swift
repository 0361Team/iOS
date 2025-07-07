//
//  FileListView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 3/29/25.
//

import SwiftUI

struct FolderListView: View {
    @StateObject private var viewModel = FolderViewModel()
    @State private var isSelected: Bool = true
    @State private var showAddFolderAlert = false
    @State private var newFolderName = ""

    let userId: Int = Int(KeychainHelper.shared.read(forKey: "userId")!)! // TODO: 실제 로그인한 사용자 ID로 바꾸세요

    var body: some View {
        GeometryReader { geo in
            NavigationStack {
                VStack {
                    UpperView()
                    Spacer().frame(height: geo.size.height * 0.05)
                    
                    defaultFolder(isSelected: $isSelected) {
                        showAddFolderAlert = true
                    }
                    
                    if isSelected {
                        if viewModel.isLoading {
                            ProgressView("폴더 불러오는 중...")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 30)
                        } else {
                            ForEach(viewModel.folders) { folder in
                                NavigationLink(destination: WeekListView(course: folder, onDeleteSuccess: {
                                    viewModel.fetchFolders(userId: userId)
                                })) {
                                    Folder(folderName: folder.title)
                                        .padding(.leading)
                                }
                            }
                        }
                    }
                }
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding()
            .alert("새 폴더 생성", isPresented: $showAddFolderAlert) {
                TextField("수업 이름", text: $newFolderName)
                Button("추가") {
                    let trimmed = newFolderName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        viewModel.addFolder(name: trimmed, userId: userId)
                        newFolderName = ""
                    }
                }
                Button("취소", role: .cancel) {
                    newFolderName = ""
                }
            }
            .onAppear {
                viewModel.fetchFolders(userId: userId)
            }
        }
    }
}

struct UpperView: View {
    var body: some View {
        HStack {
            Text("폴더")
                .font(.system(size: 28, weight: .bold))
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct defaultFolder: View {
    @Binding var isSelected: Bool
    var onAddFolder: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "tray.2")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.blue)
            Text("기본 폴더")
                .font(.system(size: 18, weight: .semibold))
            Button(action: onAddFolder) {
                Image(systemName: "plus")
                    .foregroundColor(.gray)
            }
            Button(action: {
                isSelected.toggle()
            }) {
                Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Folder: View {
    let folderName: String

    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(Color(hex: "#95a8ed"))
            Text(folderName)
                .foregroundColor(Color(hex: "#2b2b2b"))
        }
        .font(.system(size: 18, weight: .semibold))
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    FolderListView()
}
