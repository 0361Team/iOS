# iOS

<img width="1536" height="1024" alt="image (2)" src="https://github.com/user-attachments/assets/71451b82-e8b3-4a8f-a31d-7aff9b594709" />

## 시뮬레이션
https://rectangular-octave-347.notion.site/iOS-Lecture2Quiz-2025-03-202f6f40b4248043ba0edcfee41460c2

---

## 🔍 프로젝트 개요

"Lecture2Quiz"는 수업 중 녹음한 음성을 자동으로 텍스트로 변환하고, 해당 내용을 바탕으로 **퀴즈를 생성·학습할 수 있는 iOS 앱**입니다. 음성 인식에는 OpenAI Whisper 기반 STT 서버를 사용하며, 사용자의 학습 지속성과 이해도를 높이기 위해 **카드덱 퀴즈 UI**와 **퀴즈 세션 기록 관리** 기능을 포함하고 있습니다. 

STT 처리가 된 텍스트는 벡터 데이터베이스를 통해 “외부 지식 검색” + “문맥 확장” 처리를 하여 RAG 시스템 아키텍처를 통해 컨텍스트 최적화를 진행하여 Claude API를 통해 퀴즈를 생성합니다.


<img width="935" height="706" alt="KakaoTalk_Photo_2025-05-30-00-55-51-1 (1)" src="https://github.com/user-attachments/assets/45dad708-1f87-4966-b0f1-df471b007885" />



## 💬  역할

**모든 iOS 프론트 앱 개발을 혼자 하였습니다. 추가로 디자이너가 없는 프로젝트입니다.**

**프론트 개발자 - 1인**

백엔드 개발자 - 2인

백엔드 + AI 개발자 - 1인

---

## 🛠 사용 기술 스택

- **Frontend**: SwiftUI, MVVM 아키텍처
- **STT 처리**: OpenAI Whisper (WebSocket 기반 실시간 음성 스트리밍)
- **네트워크**: Moya + REST API, WebSocket 통신
- **오디오 처리**: AVAudioEngine, AVAudioConverter, 실시간 리샘플링 및 RMS 정규화
- **UX 최적화**: 퀴즈 카드덱 슬라이딩 UI, 세션 재개 기능, 뷰 상태 자동 갱신

---

## 💡 주요 기능

- 🔊 **실시간 음성 스트리밍**: AVAudioEngine을 활용한 실시간 녹음 및 Whisper 서버로 음성 전송
- 📄 **STT 결과 전처리**: 낮은 볼륨의 음성에 대한 RMS 기반 정규화 처리, End-of-Audio 자동 전송
- 🧠 **퀴즈 생성 및 풀이**: STT 결과로부터 자동 생성된 퀴즈를 카드덱 UI로 풀고, 정답/오답 기록
- 🔁 **세션 이어풀기**: 미완료된 퀴즈 세션을 이어서 풀 수 있는 기능 제공
- 📋 **퀴즈 기록 관리**: 완료된 세션은 점수 확인, 미완료 세션은 이어서 풀이 기능 제공

---

## 🔎 오픈 소스 기여

- https://github.com/collabora/WhisperLive

실시간 Whisper STT 통신을 iOS로 구현하여 WebSocket 통신 iOS Client 코드로 기여하였습니다.
