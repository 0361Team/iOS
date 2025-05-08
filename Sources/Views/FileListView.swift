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
    
    var body: some View {
        GeometryReader { geo in
            VStack(){
                
                UpperView() // 네비게이션 바
                Spacer().frame(height: geo.size.height * 0.05)
                // 기본 폴더
                defaultFolder(isSelected: $isSelected) {
                    showAddFolderAlert = true
                }
                if isSelected {
                    ForEach (viewModel.folders) { folder in
                        Folder(folderName: folder.name)
                            .padding(.leading)
                    }
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding()
                .alert("새 폴더 생성", isPresented: $showAddFolderAlert) {
                    TextField("폴더 이름", text: $newFolderName)
                    Button("추가") {
                        if !newFolderName.trimmingCharacters(in: .whitespaces).isEmpty {
                            viewModel.addFolder(name: newFolderName)
                            newFolderName = ""
                        }
                    }
                    Button("취소", role: .cancel) {
                        newFolderName = ""
                    }
                }
            
        }
    }

}


struct UpperView: View {

    var body: some View {
        HStack{
            Text("폴더")
                .font(Font.Pretend.pretendardExtraBold(size: 28))
            Spacer()
            Button(action:{print("로그아웃")}){Image("logout")}
                .frame(width: 35,height: 35)
        }
        .padding(.horizontal)
    }
}

struct defaultFolder: View {
    @Binding var isSelected: Bool
    var onAddFolder: () -> Void  // ⬅️ 외부에서 액션 주입
    
    var body: some View {
        HStack{
            Image(systemName: "tray.2")
                .font(Font.Pretend.pretendardBold(size: 18))
            Text("기본 폴더")
                .font(Font.Pretend.pretendardBold(size: 18))
            Spacer()
            Button(action: {
                onAddFolder()
            }){
                Image(systemName: "plus")
                    .font(Font.Pretend.pretendardRegular(size: 18))
                    .foregroundStyle(Color.gray)
            }
            
            if isSelected {
                Button(action: {
                    isSelected.toggle()
                }){
                    Image(systemName: "chevron.up")
                        .font(Font.Pretend.pretendardRegular(size: 18))
                        .foregroundStyle(Color.gray)
                }
            }else{
                Button(action: {
                    isSelected.toggle()
                }){
                    Image(systemName: "chevron.down")
                        .font(Font.Pretend.pretendardRegular(size: 18))
                        .foregroundStyle(Color.gray)
                }
            }
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }
}


struct Folder: View{
    let folderName: String
    
    var body: some View {
            HStack {
                Button(action: {
                    print("Selected folder: \(folderName)")
                }, label: {
                    Image(systemName:"folder")
                        .foregroundStyle(Color.black)
                        .font(Font.Pretend.pretendardSemiBold(size: 18))
                    Text(folderName)
                        .foregroundStyle(Color.black)
                        .font(Font.Pretend.pretendardSemiBold(size: 18))
                })
                .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        
    }
}

#Preview {
    FolderListView()
}
