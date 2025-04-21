import SwiftUI
import FirebaseFirestore

struct EventDetailsScreen: View {
    let eventName: String
    @StateObject private var viewModel = EventViewModel()
    
    // Photo picker state
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    // Editor states
    @State private var showingTitleEditor = false
    @State private var showingSubtitleEditor = false
    @State private var showingButtonEditor = false
    @State private var showingDatePicker = false
    
    // Temporary edit states
    @State private var tempTitle = "Hi"
    @State private var tempSubtitle = ""
    @State private var tempButtonText = "Take Photos →"
    
    // Picker options
    let revealOptions = ["Immediately", "1 hour after", "12 hours after", "24 hours after", "48 hours after"]
    let photosOptions = [5, 10, 15, 20, 30, 50]
    let maxGuestsOptions = [5, 10, 20, 30, 50, 100]
    
    // Fixed dimensions for preview card
    private let previewCardHeight: CGFloat = 450 // Increased height
    private let previewCardWidth: CGFloat = 240 // Even larger width for better centering
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E MMM d • h:mma zzz"
        return formatter
    }()
    
    init(eventName: String) {
        self.eventName = eventName
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 30) {
                    // Preview section - redesigned with better centering and right-corner options
                    previewSection
                    
                    // Settings section
                    settingsSection
                    
                    // Continue button
                    continueButton
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 5) // Reduced overall horizontal padding
        }
        .navigationBarTitle("Event Details", displayMode: .inline)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $inputImage)
        }
        .alert("Edit Title", isPresented: $showingTitleEditor) {
            TextField("Title", text: $tempTitle)
            Button("Cancel", role: .cancel) { }
            Button("OK") { viewModel.updateEventTitle(tempTitle) }
        }
        .alert("Edit Subtitle", isPresented: $showingSubtitleEditor) {
            TextField("Subtitle", text: $tempSubtitle)
            Button("Cancel", role: .cancel) { }
            Button("OK") { viewModel.updateEventSubtitle(tempSubtitle) }
        }
        .alert("Edit Button Text", isPresented: $showingButtonEditor) {
            TextField("Button Text", text: $tempButtonText)
            Button("Cancel", role: .cancel) { }
            Button("OK") { viewModel.updateButtonText(tempButtonText) }
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
        .onAppear {
            initializeEvent()
        }
    }
    
    // MARK: - Subviews
    
    private var previewSection: some View {
        // Layout with centered preview card and right-corner edit buttons
        VStack(spacing: 15) {
            Text("Preview")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(alignment: .top) {
                Spacer(minLength: 20) // Left margin
                
                // Preview Card - CENTERED
                previewCard
                    .frame(width: previewCardWidth, height: previewCardHeight)
                
                Spacer() // Flexible space to push buttons to the right
                
                // Edit Buttons - MOVED TO FAR RIGHT
                editButtons
                    .frame(width: 70)
                    .padding(.trailing, 5)
            }
        }
        .padding(.top, 10)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
        .padding(.horizontal, 0) // Remove horizontal padding to allow more space
    }
    
    private var previewCard: some View {
        ZStack(alignment: .center) {
            // Fixed background regardless of image
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.3))
                .frame(width: previewCardWidth, height: previewCardHeight)
            
            // Image if available (constrained to exact same size as background)
            if let image = inputImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: previewCardWidth, height: previewCardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            // Semi-transparent overlay for better text visibility
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
                .frame(width: previewCardWidth, height: previewCardHeight)
            
            // Content overlay
            VStack(spacing: 12) {
                Spacer()
                
                VStack(spacing: 10) {
                    Text(tempTitle)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    if !tempSubtitle.isEmpty {
                        Text(tempSubtitle)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text(dateFormatter.string(from: Date()).components(separatedBy: " • ")[0])
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button(action: {}) {
                        Text(tempButtonText)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: previewCardWidth - 50, height: 56)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(28)
                    }
                }
                .padding(.bottom, 32)
            }
            .frame(width: previewCardWidth)
        }
        .frame(width: previewCardWidth, height: previewCardHeight)
        // Add shadow for better visual separation
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private var editButtons: some View {
        VStack(spacing: 24) {
            // More stylish edit buttons with increased spacing
            editButton("Photo", systemName: "photo.fill") {
                showingImagePicker = true
            }
            editButton("Title", systemName: "textformat.alt") {
                showingTitleEditor = true
            }
            editButton("Text", systemName: "text.quote") {
                showingSubtitleEditor = true
            }
            editButton("Button", systemName: "rectangle.and.pencil.and.ellipsis") {
                showingButtonEditor = true
            }
        }
        .padding(.top, 16)
    }
    
    private func editButton(_ label: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 54, height: 54)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: systemName)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var settingsSection: some View {
        VStack(spacing: 5) {
            HStack {
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
            
            VStack(spacing: 0) {
                settingRow("Ending", value: dateFormatter.string(from: viewModel.loadedEvent?.endDate?.dateValue() ?? Date())) {
                    showingDatePicker = true
                }
                
                Divider().background(Color.gray.opacity(0.5))
                
                menuSettingRow("Reveal Photo", value: viewModel.loadedEvent?.revealPhotosTiming ?? "12 hours after", options: revealOptions) {
                    viewModel.updateRevealPhotosTiming($0)
                }
                
                Divider().background(Color.gray.opacity(0.5))
                
                menuSettingRow("Photos per Person", value: "\(viewModel.loadedEvent?.photosPerPerson ?? 10) Photos", options: photosOptions.map { "\($0) Photos" }) {
                    if let intValue = Int($0.components(separatedBy: " ")[0]) {
                        viewModel.updatePhotosPerPerson(intValue)
                    }
                }
                
                Divider().background(Color.gray.opacity(0.5))
                
                HStack {
                    menuSettingRow("Number of participants", value: "Up to \(viewModel.loadedEvent?.maxGuests ?? 10) guests", options: maxGuestsOptions.map { "Up to \($0) guests" }) {
                        if let intValue = Int($0.components(separatedBy: " ")[2]) {
                            viewModel.updateMaxGuests(intValue)
                        }
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6).opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private func settingRow(_ label: String, value: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Button(action: action) {
                HStack {
                    Text(value)
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    private func menuSettingRow(_ label: String, value: String, options: [String], action: @escaping (String) -> Void) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(action: { action(option) }) {
                        Text(option)
                    }
                }
            } label: {
                HStack {
                    Text(value)
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    private var continueButton: some View {
        Button(action: createEvent) {
            Text("Add a Photo to Continue →")
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(inputImage != nil ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(inputImage == nil)
        .padding(.horizontal)
    }
    
    private var datePickerSheet: some View {
        VStack {
            DatePicker(
                "Select end date",
                selection: Binding(
                    get: { viewModel.loadedEvent?.endDate?.dateValue() ?? Date() },
                    set: { viewModel.updateEndDate($0) }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            
            Button("Done") {
                showingDatePicker = false
            }
            .padding()
        }
    }
    
    // MARK: - Methods
    
    private func initializeEvent() {
        let event = EventModel(
            id: UUID().uuidString,
            eventName: eventName,
            title: "Hi",
            subtitle: "",
            buttonText: "Take Photos →",
            backgroundImageUrl: "",
            creatorId: "",
            status: "active",
            endDate: Timestamp(date: Date(timeIntervalSinceNow: 7 * 24 * 60 * 60)),
            createdAt: Timestamp(date: Date()),
            revealPhotosTiming: "12 hours after",
            photosPerPerson: 10,
            maxGuests: 10,
            galleryAccess: true,
            participants: []
        )
        viewModel.populateFromEvent(event: event)
    }
    
    private func createEvent() {
        viewModel.updateEventName(eventName)
        if let image = inputImage {
            viewModel.updateBackgroundImage(image)
        }
        viewModel.createEvent()
    }
}

// ImagePicker implementation remains unchanged
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EventDetailsScreen_Previews: PreviewProvider {
    static var previews: some View {
        EventDetailsScreen(eventName: "Birthday Party")
    }
}
