# EuclidV2: AI-Powered Mathematical Expression Solver

## 📖 Overview

EuclidV2 is an interactive mathematical expression solver that allows users to draw mathematical equations and receive instant solutions. Powered by Google's Gemini AI, this app can recognize and solve handwritten math problems, equations, and even interpret graphical math concepts.

## ✨ Features

- **Handwriting Recognition**: Solve math problems by drawing them directly on the canvas
- **Multi-Color Support**: Use different colors to enhance your mathematical illustrations
- **Adjustable Stroke Width**: Fine-tune your drawing precision
- **Real-Time Processing**: Get instant solutions from the advanced AI backend
- **Support for Multiple Types**:
  - Basic expressions (2+2, 3×4)
  - Equations (x²+2x+1=0)
  - Variable assignments (x=5)
  - Graphical math problems
  - Abstract mathematical concepts

## 🛠️ Technology Stack

- **Frontend**: Flutter (Cross-platform mobile framework)
- **Backend**: Go (Golang)
- **AI**: Google Gemini 2.5 Flash API
- **Deployment**: Render (Backend hosting)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Go (1.20 or higher)
- Google Gemini API key

### Frontend Setup

1. Clone the repository:
```
git clone https://github.com/HimalThapaMagar/EuclidV2.git
cd EuclidV2
```
2. Install dependencies
```
flutter pub get
```
3. Run the application onto your choice of platform.
```
flutter run
```

### BackEnd Setup

1. Navigate to the backend service
```
cd backend
```

2. Set your own Gemini API key
```
export GEMINI_API_KEY="your api key goes here, user, please don't steal mine if your find it in my project somewhere... Thanks"

3. Run the backend service
```
go run main.go


## 🔍 How It Works

1. **Draw**: Use your finger or stylus to draw mathematical expressions
2. **Process**: Tap the check mark to send your drawing to the AI
3. **View Results**: Get solutions displayed at the top of the screen

## 🌱 Future Enhancements

- Text annotation support for labeling elements
- History of solved problems
- Step-by-step solution explanations
- Shareable solution cards
- Dark mode support
- Offline processing for basic expressions

## 👥 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

