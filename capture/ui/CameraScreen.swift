//
//  CameraScreen.swift
//  capture
//
//  Created by Leslie Annan on 21/04/2025.
//

import SwiftUI
import AVFoundation
import FirebaseFirestore

struct CameraScreen: View {
    @StateObject private var viewModel = EventViewModel()
    @State private var showCamera = false
    @State private var selectedEvent: EventModel? = nil
    @State private var navigateToEventDetails = false
    
    // Using light theme colors
    private var backgroundColor: Color {
        Color(.systemBackground) // Light theme background
    }
    
    private var textColor: Color {
        .black // Light theme text
    }
    
    private var secondaryTextColor: Color {
        Color(.darkGray) // Light theme secondary text
    }
    
    private var actionButtonsBackground: Color {
        Color(.systemGray5) // Light theme button background
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .leading, spacing: 0) {
                    // Header - matching Settings title style and position
                    Text("Hosting")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                        .padding(.horizontal)
                    
                    // List of events - removed extra spacing at bottom by using Spacer.minimumSpace
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.hostedEvents) { event in
                                EventRow(event: event, onEditTapped: {
                                    // Handle edit button tap
                                    selectedEvent = event
                                    navigateToEventDetails = true
                                })
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                            }
                        }
                        .padding(.top, 10)
                    }
                    // This spacer will minimize extra space at the bottom
                    Spacer(minLength: 0)
                    
                    // Hidden NavigationLink that will be activated programmatically
                    NavigationLink(
                        destination: EventDetailsScreen(
                            eventName: selectedEvent?.eventName ?? "",
                            existingEvent: selectedEvent,
                            isEditMode: true
                        ),
                        isActive: $navigateToEventDetails
                    ) {
                        EmptyView()
                    }
                    .opacity(0) // Hide the link
                    .frame(width: 0, height: 0)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Reload events every time the screen appears
                print("CameraScreen appeared - reloading events")
                // Directly call the private loadEvents method instead
                viewModel.loadEvents()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    struct EventRow: View {
        let event: EventModel
        let onEditTapped: () -> Void
        
        // Light theme colors
        private var textColor: Color {
            .black
        }
        
        private var secondaryTextColor: Color {
            Color(.darkGray)
        }
        
        private var cardBackground: Color {
            .white
        }
        
        private var buttonBgColor: Color {
            Color(.systemGray5)
        }
        
        var body: some View {
            VStack(spacing: 0) {
                // Event row content
                HStack(spacing: 12) {
                    // Event thumbnail
                    EventThumbnail(imageUrl: event.backgroundImageUrl)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                    
                    // Event details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.eventName)
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        Text(getEventTimeStatus(event: event))
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    Spacer()
                }
                .padding()
                
                // Action buttons
                EventActionButtons(onEditTapped: onEditTapped)
                    .padding(.bottom, 12)
                    .padding(.horizontal)
            }
            .background(cardBackground)
        }
        
        // Helper function to calculate the time status
        private func getEventTimeStatus(event: EventModel) -> String {
            guard let endDate = event.endDate else {
                return "No end date"
            }
            
            let now = Date()
            let endDateTime = endDate.dateValue()
            
            if endDateTime < now {
                return "Ended"
            } else {
                let components = Calendar.current.dateComponents([.day, .hour], from: now, to: endDateTime)
                
                if let days = components.day, days > 0 {
                    return "Ending \(days)d from now"
                } else if let hours = components.hour, hours > 0 {
                    return "Ending \(hours)h from now"
                } else {
                    return "Ending soon"
                }
            }
        }
    }
    
    // Thumbnail view that loads image from URL using AsyncImage
    struct EventThumbnail: View {
        let imageUrl: String
        
        var body: some View {
            if !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .foregroundColor(.black)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 60)
                .clipped()
                .background(Color.gray.opacity(0.3))
            } else {
                // Placeholder
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
                .frame(width: 60, height: 60)
            }
        }
    }
    
    // Action buttons for each event
    struct EventActionButtons: View {
        let onEditTapped: () -> Void
        
        // Light theme background
        private var buttonBgColor: Color {
            Color(.systemGray5)
        }
        
        var body: some View {
            HStack(spacing: 0) {
                // Camera button
                ActionButton(icon: "camera") {
                    // Camera action
                }
                
                // Edit button with explicit tap handler
                Button(action: onEditTapped) {
                    Image(systemName: "pencil")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .contentShape(Rectangle())  // Make entire area tappable
                .buttonStyle(PlainButtonStyle())
                
                // Share button
                ActionButton(icon: "square.and.arrow.up") {
                    // Share action
                }
                
                // QR code button
                ActionButton(icon: "qrcode") {
                    // QR code action
                }
            }
            .background(buttonBgColor)
            .cornerRadius(28)
        }
    }
    
    // Individual action button
    struct ActionButton: View {
        let icon: String
        let action: () -> Void
        
        // Light theme icon color
        private var iconColor: Color {
            .black
        }
        
        var body: some View {
            Button(action: action) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                    .foregroundColor(iconColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .contentShape(Rectangle())  // Make entire area tappable
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct CameraScreen_Previews: PreviewProvider {
    static var previews: some View {
        CameraScreen()
    }
}
