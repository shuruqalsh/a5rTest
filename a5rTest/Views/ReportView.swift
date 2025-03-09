//
//  ReportView.swift
//  a5rTest
//
//  Created by shuruq alshammari on 07/09/1446 AH.
//

import Foundation
import SwiftUI



 // 🔥 للتحكم في إغلاق الصفحة وإعلام العرض الرئيسي
 


// نموذج للوضعيات لعرضها في التقرير
struct Posture: Identifiable {
    let id = UUID()
    let name: String
    let correctImage: String // اسم صورة الوضعية الصحيحة
    let wrongImage: String // اسم صورة الوضعية الخاطئة
}

// صفحة التقرير
struct ReportView: View {
    // 🆕 قائمة الوضعيات الخاطئة (تأتي من الكاميرا)
    let wrongPostures: [Posture]
    @State private var showPostureList = false
    let elapsedTime: TimeInterval // 🆕 استقبال الوقت المستغرق
    
    @State private var isShowingHomePage = false // 

    
    @Environment(\.presentationMode) var presentationMode

    
    var body: some View {
        ZStack {
            Color(hex: "#141F25")
                .ignoresSafeArea()
            
            ScrollView {
                VStack {
                    
                    VStack(alignment: .leading, spacing: -10) { // تقليل المسافة العمودية بين العناصر

                        HStack{
                            Text("Presentation Time")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.leading, 20) // مسافة إضافية من اليسار

                            Spacer()
                            
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image("ReRecording") // اسم الصورة هنا
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 38.25, height: 42.5)
                                    .padding(.trailing, 20)
                            }

                                
                            
                            
                            }

                        HStack (spacing:8){
                            
                            Image("Time")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 23.33, height: 25.45)
                            
                            Text("\(formatTime(elapsedTime)) m")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            
                        }
                        .padding(.leading, 20) // مسافة إضافية من اليسار
                        
                        }
                    .padding(.top, 10)
              
                    VStack(spacing:3){
                        
                        HStack{
                            Image("Rectangle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 19, height: 19)
                            
                            Text("Posture Gaps")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()

                            Image("Rectangle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 19, height: 19)
                            
                            Text("Speaking Gaps")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                        }
                        
                        HStack{
                            Text("\(wrongPostures.count)")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.leading, 30) // مسافة إضافية من اليسار

                            Spacer()

                            Text("\(wrongPostures.count)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.trailing, 120) // مسافة إضافية من اليمين

                        }
                    }
                    .padding(.trailing) // مسافة إضافية من اليمين
                    .padding(.leading) // مسافة إضافية من اليسار

                    ZStack{
                    Image("BodyBox")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 365, height: 200)
                    
                    HStack {
                        Text("See Your Posture Gaps vs. Correct \nPosture!")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 300, height: 50, alignment: .leading) // تحديد العرض والارتفاع والمحاذاة

                            .foregroundColor(.white)
                            .padding(.top,130) // مسافة إضافيمن اليسار

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showPostureList.toggle()
                            }
                        }) {
                            Image(showPostureList ? "ArrowDown" : "ArrowUp")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .padding(.top,130) // مسافة إضافية من اليسار

                        }

                    }
                }
                
                    if showPostureList {
                        VStack(spacing: 10) {
                            ForEach(Array(wrongPostures.enumerated()), id: \.element.id) { index, posture in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("\(index + 1). \(posture.name)")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading) // محاذاة إلى اليسار
                                        .padding(.horizontal, 10) // مسافة من اليمين واليسار
                                        .lineLimit(nil) // السماح بأكثر من سطر
                                        .multilineTextAlignment(.leading) // محاذاة النص إلى اليسار

                                    HStack(spacing: 10) { // تقليل المسافة بين الصور
                                        Image(posture.correctImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: 160, maxHeight: 150)
                                            .border(Color.green, width: 2)
                                            .cornerRadius(10) // ✅ تغيير القيمة لتكبير أو تصغير نصف القطر

                                        Spacer()
                                        
                                        Image(posture.wrongImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: 160, maxHeight: 150)
                                            .border(Color(hex: "#FFC700"), width: 2)

                                    }
                                }
                                .padding(10)
                                .background(Color(hex: "#141F25"))
                                .cornerRadius(10)
                                .clipped() // منع المحتوى من الخروج من الحواف
                            }
                        }
                        .frame(maxWidth: 365) // ✅ ضبط العرض ليطابق البوكس الخلفي
                        .background(Color(hex: "#141F25"))
                        .border(Color(hex: "#38464F"), width: 2)
                        .transition(.opacity)                    }
                
                    
                }
                
                ZStack{
                    Image("VoiceBox")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 365, height: 200)
                        .padding(.top, 10)
                    
                    HStack {
                        Text("See Your Posture Gaps vs. Correct \nPosture!")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 300, height: 50, alignment: .leading) // تحديد العرض والارتفاع والمحاذاة

                            .foregroundColor(.white)
                            .padding(.top,130) // مسافة إضافيمن اليسار

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showPostureList.toggle()
                            }
                        }) {
                            Image(showPostureList ? "ArrowDown" : "ArrowUp")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .padding(.top,130) // مسافة إضافية من اليسار

                        }

                    }
                }
                    
                // 🆕 زر "Back" للعودة
                Button("Back") {
                }
                .frame(width: 370, height: 63)
                .font(.system(size: 20, weight: .semibold))
                .background(Color(hex: "#CFF39A"))
                .foregroundColor(.black)
                .cornerRadius(20)
                .padding(.top, 30)

            }
        }
    }
    // 🆕 دالة لتحويل الوقت المستغرق إلى صيغة "دقائق:ثواني"
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%01d:%02d", minutes, seconds)
    }
}

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        ReportView(
            wrongPostures: [
                Posture(name: "لمس الرقبة", correctImage: "correct1", wrongImage: "wrong1"),
                Posture(name: "تكتيف الأذرع", correctImage: "correct2", wrongImage: "wrong2")
            ],
            elapsedTime: 123 // 🕒 الوقت المستغرق بالثواني (مثلاً دقيقتين و3 ثواني)
        )
    }
}
