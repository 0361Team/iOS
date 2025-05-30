    //
    //  HomeView.swift
    //  Lecture2Quiz
    //
    //  Created by 바견규 on 4/5/25.
    //
    import SwiftUI

    struct HomeView: View {
        @Binding var selectedTab: String

        var body: some View {
            NavigationStack(){
                ZStack {
                    Color.white.ignoresSafeArea()
                    FloatingMenuButton(selectedTab: $selectedTab)
                }
            }
            
        }
    }


    struct FloatingMenuButton: View {
        @State private var isExpanded = false
        @Binding var selectedTab: String
        @ObservedObject private var folderViewModel = FolderViewModel()
        
        // 버튼 정보 배열
        let menuItems: [(icon: String, label: String)] = [
            ("note.text.badge.plus", "새 노트"),
            ("mic.fill", "녹음")
        ]
        
        // 모달뷰
        @State private var showRecordingModal = false
        
        var body: some View {
            VStack {
                Spacer()
                HStack {
                    Spacer()

                    ZStack(alignment: .bottomTrailing) {
                        // 펼쳐질 버튼 목록
                        VStack(alignment: .trailing, spacing: 16) {
                            ForEach(menuItems.indices.reversed(), id: \.self) { index in
                                HStack(spacing: 10) {
                                    // 텍스트
                                    Text(menuItems[index].label)
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                        .opacity(isExpanded ? 1 : 0)
                                        .offset(y: isExpanded ? 0 : 20)
                                        .animation(
                                            .easeOut.delay(Double(index) * 0.05),
                                            value: isExpanded
                                        )

                                    // 버튼
                                    FloatingSubButton(iconName: menuItems[index].icon) {
                                        if menuItems[index].label == "녹음"{
                                            withAnimation {
                                                showRecordingModal = true
                                            }
                                        }
                                        if menuItems[index].label == "새 노트"{
                                            selectedTab = "Class"
                                        }
                                    }
                                    .scaleEffect(isExpanded ? 1 : 0.6)
                                    .opacity(isExpanded ? 1 : 0)
                                    .offset(y: isExpanded ? 0 : 30)
                                    .animation(
                                        .spring(response: 0.4, dampingFraction: 0.7)
                                            .delay(Double(index) * 0.05),
                                        value: isExpanded
                                    )
                                }
                            }
                            
                        }
                        .padding(.bottom, 80)
                        .padding(.trailing, 8)
                        

                        //모달뷰
                        if showRecordingModal {
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    withAnimation {
                                        showRecordingModal = false
                                    }
                                }

                            RecordingModal(
                                onDismiss: {
                                    withAnimation {
                                        showRecordingModal = false
                                    }
                                }
                            )
                            .zIndex(1)
                        }

                        
                        // 메인 버튼
                        FloatingSubButton(iconName: isExpanded ? "xmark" : "plus") {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    struct FloatingSubButton: View {
        var iconName: String
        var action: () -> Void

        var body: some View {
            Button(action: action) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
        }
    }






    #Preview {
    }
