import sys
import os
import asyncio
from PyQt5.QtWidgets import (QApplication, QWidget, QLabel, QTextEdit, 
                             QComboBox, QSlider, QPushButton, QVBoxLayout, 
                             QHBoxLayout, QFileDialog, QMessageBox)
from PyQt5.QtCore import Qt
import edge_tts

# 캐릭터 보이스 데이터베이스 (에반게리온 모드 최적화)
VOICE_PRESETS = {
    "신지 (차분하고 표준 남성)": "ko-KR-InJoonNeural",
    "카오루 (톤이 낮고 부드러운 남성)": "ko-KR-InJoonNeural",
    "아스카 (쾌활하고 까칠한 여성)": "ko-KR-SunHiNeural",
    "레이 (톤이 낮고 감정 없는 여성)": "ko-KR-SunHiNeural",
}

class VoiceGeneratorGUI(QWidget):
    def __init__(self):
        super().__init__()
        self.initUI()
        
    def initUI(self):
        self.setWindowTitle('🎤 FNF 에바 모드 전용 - AI 보이스 생성기 v1.0')
        self.resize(550, 450)
        
        # 메인 레이아웃
        layout = QVBoxLayout()
        
        # 1. 캐릭터 선택
        layout.addWidget(QLabel('👤 캐릭터 목소리 선택:'))
        self.char_combo = QComboBox()
        self.char_combo.addItems(VOICE_PRESETS.keys())
        self.char_combo.setCurrentText("아스카 (쾌활하고 까칠한 여성)") # 기본값은 아스카 ㅋㅋ
        layout.addWidget(self.char_combo)
        
        # 2. 대사 입력창
        layout.addWidget(QLabel('💬 생성할 대사 입력 (마침표, 쉼표로 쉼표 타이밍 조절 가능):'))
        self.text_input = QTextEdit()
        self.text_input.setPlaceholderText("안타 바카?! 감히 내 파일을 조작하려 들다니, 한심하긴!\n(예: 안타 바카?! 내 코드를 함부로 조작하다니!)")
        layout.addWidget(self.text_input)
        
        # 3. 속도 조절 (Rate)
        self.rate_label = QLabel('⚡ 속도 (Speed): +10%')
        layout.addWidget(self.rate_label)
        self.rate_slider = QSlider(Qt.Horizontal)
        self.rate_slider.setMinimum(-50)
        self.rate_slider.setMaximum(50)
        self.rate_slider.setValue(0)
        self.rate_slider.valueChanged.connect(self.update_labels)
        layout.addWidget(self.rate_slider)
        
        # 4. 높낮이 조절 (Pitch)
        self.pitch_label = QLabel('🎵 높낮이 (Pitch): +12Hz')
        layout.addWidget(self.pitch_label)
        self.pitch_slider = QSlider(Qt.Horizontal)
        self.pitch_slider.setMinimum(-50)
        self.pitch_slider.setMaximum(50)
        self.pitch_slider.setValue(0)
        self.pitch_slider.valueChanged.connect(self.update_labels)
        layout.addWidget(self.pitch_slider)
        
        # 5. 생성 버튼
        self.btn_generate = QPushButton('💾 AI 보이스 파일 생성 및 저장')
        self.btn_generate.setStyleSheet("background-color: #4CAF50; color: white; font-weight: bold; font-size: 14px; padding: 10px;")
        self.btn_generate.clicked.connect(self.start_generation)
        layout.addWidget(self.btn_generate)
        
        self.setLayout(layout)
        
    def update_labels(self):
        self.rate_label.setText(f'⚡ 속도 (Speed): {self.rate_slider.value()}%')
        self.pitch_label.setText(f'🎵 높낮이 (Pitch): {self.pitch_slider.value()}Hz')
        
    def start_generation(self):
        text = self.text_input.toPlainText().strip()
        if not text:
            QMessageBox.warning(self, '경고', '대사를 먼저 입력해야 목소리를 만들지! 바보야!')
            return
            
        # 저장할 파일 경로 선택 창 띄우기
        file_path, _ = QFileDialog.getSaveFileName(self, "보이스 저장", "", "MP3 Files (*.mp3);;All Files (*)")
        if not file_path:
            return
            
        # 값 파싱
        preset = self.char_combo.currentText()
        voice = VOICE_PRESETS[preset]
        
        # 슬라이더 값을 edge-tts 포맷 부호(+/-)로 변환
        rate_val = self.rate_slider.value()
        rate_str = f"{rate_val:+}%"
        
        pitch_val = self.pitch_slider.value()
        pitch_str = f"{pitch_val:+}Hz"
        
        # 비동기 TTS 실행
        self.btn_generate.setEnabled(False)
        self.btn_generate.setText('⏳ AI가 열일하며 목소리 굽는 중...')
        QApplication.processEvents()
        
        asyncio.run(self.run_tts(text, voice, rate_str, pitch_str, file_path))
        
        self.btn_generate.setEnabled(True)
        self.btn_generate.setText('💾 AI 보이스 파일 생성 및 저장')
        QMessageBox.information(self, '성공', f'음성 파일이 성공적으로 구워졌어!\n경로: {file_path}')
        
    async def run_tts(self, text, voice, rate, pitch, output_path):
        communicate = edge_tts.Communicate(text, voice, rate=rate, pitch=pitch)
        await communicate.save(output_path)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    ex = VoiceGeneratorGUI()
    self_style = """
        QWidget { font-family: 'Malgun Gothic'; font-size: 12px; }
        QLabel { font-weight: bold; margin-top: 5px; }
    """
    app.setStyleSheet(self_style)
    ex.show()
    sys.exit(app.exec_() or 0)
