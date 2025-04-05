//
//  ViewController.swift
//  Afisha
//
//  Created by Marjona Davlyatova on 02.04.2025.
//
import UIKit

class ViewController: UIViewController {

    static var shared: ViewController!

    var hallInfo: HallInfo?
    var selectedSeats: [Seat] = []

    let scrollView = UIScrollView()
    let schemeView = UIView()
    let bottomCard = UIView()
    let priceLabel = UILabel()
    let noteLabel = UILabel()
    let buyButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController.shared = self
        view.backgroundColor = .white
        setupBottomCard()
        fetchData()
    }

    func fetchData() {
        guard let url = URL(string: "https://madridist20.github.io/test11/seat.json") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                do {
                    let info = try JSONDecoder().decode(HallInfo.self, from: data)
                    DispatchQueue.main.async {
                        self.hallInfo = info
                        SeatTypeProvider.shared.configure(with: info.seats_type)
                        self.updateUI()
                    }
                } catch {
                    print("❌ Ошибка парсинга JSON: \(error)")
                }
            }
        }.resume()
    }

    func updateUI() {
        guard let info = hallInfo else { return }
        addHeader(info)
        setupScroll()
        drawSeats(info.seats)
    }

    func addHeader(_ info: HallInfo) {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        stack.addArrangedSubview(createLabel(info.hall_name, size: 18, bold: true, center: true))
        stack.addArrangedSubview(createLegend())

        let remaining = info.seats.filter { $0.booked_seats == 0 && $0.object_type.contains("seat") }.count
        stack.addArrangedSubview(createLabel("Осталось мест: \(remaining)", size: 14, bold: false, center: true, color: .gray))

        if info.has_started {
            stack.addArrangedSubview(createLabel(info.has_started_text, size: 16, bold: false, center: true, color: .systemRed))
        }

        stack.addArrangedSubview(createLabel("ЭКРАН", size: 16, bold: true, center: true, color: .darkGray))

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    func createLabel(_ text: String, size: CGFloat, bold: Bool, center: Bool = false, color: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        label.textColor = color
        if center { label.textAlignment = .center }
        return label
    }

    func createLegend() -> UIStackView {
        let legend = UIStackView()
        legend.axis = .horizontal
        legend.spacing = 20
        legend.alignment = .center
        legend.distribution = .equalSpacing

        for (type, price) in SeatTypeProvider.shared.legendItems() {
            let colorBox = UIView()
            colorBox.backgroundColor = SeatTypeProvider.shared.color(for: type)
            colorBox.layer.cornerRadius = 4
            colorBox.translatesAutoresizingMaskIntoConstraints = false
            colorBox.widthAnchor.constraint(equalToConstant: 14).isActive = true
            colorBox.heightAnchor.constraint(equalToConstant: 14).isActive = true

            let label = UILabel()
            label.text = "\(price) TJS"
            label.font = .systemFont(ofSize: 14)

            let item = UIStackView(arrangedSubviews: [colorBox, label])
            item.axis = .horizontal
            item.spacing = 6
            legend.addArrangedSubview(item)
        }
        return legend
    }

    func setupScroll() {
        scrollView.maximumZoomScale = 3
        scrollView.minimumZoomScale = 1
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        schemeView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(schemeView)

       NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 160),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomCard.topAnchor),

            schemeView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            schemeView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            schemeView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            schemeView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            schemeView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height * 0.6)
        ])
    }

    func drawSeats(_ seats: [Seat]) {
        let grouped = Dictionary(grouping: seats.filter { $0.object_type.contains("seat") }, by: { $0.row_num })

        for (row, rowSeats) in grouped.sorted(by: { $0.key < $1.key }) {
            guard let first = rowSeats.first else { continue }
            let label = UILabel()
            label.text = row
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.textColor = .darkGray
            label.frame = CGRect(x: 4, y: first.top, width: 20, height: 20)
            schemeView.addSubview(label)

            for seat in rowSeats {
                let button = UIButton(type: .custom)
                button.frame = CGRect(x: seat.left, y: seat.top, width: 30, height: 30)
                button.layer.cornerRadius = 6
                button.setTitle(seat.object_title, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 10)
                button.tag = seat.seat_id

                button.backgroundColor = seat.booked_seats == 1 ? .lightGray : SeatTypeProvider.shared.color(for: seat.seat_type ?? "")
                button.isEnabled = seat.booked_seats == 0
                button.addTarget(self, action: #selector(seatTapped(_:)), for: .touchUpInside)

                schemeView.addSubview(button)
            }
        }
    }

    @objc func seatTapped(_ sender: UIButton) {
        guard let seat = hallInfo?.seats.first(where: { $0.seat_id == sender.tag }) else { return }

        if let index = selectedSeats.firstIndex(where: { $0.seat_id == seat.seat_id }) {
            selectedSeats.remove(at: index)
        } else {
            selectedSeats.append(seat)
        }

        for subview in schemeView.subviews {
            if let btn = subview as? UIButton,
               let seatObj = hallInfo?.seats.first(where: { $0.seat_id == btn.tag }) {
                if selectedSeats.contains(where: { $0.seat_id == seatObj.seat_id }) {
                    btn.backgroundColor = .systemGreen
                } else {
                    btn.backgroundColor = seatObj.booked_seats == 1 ? .lightGray : SeatTypeProvider.shared.color(for: seatObj.seat_type ?? "")
                }
            }
        }
        updateBottomCard()
    }

    func setupBottomCard() {
        bottomCard.backgroundColor = .systemGray6
        bottomCard.layer.cornerRadius = 16
        bottomCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomCard)

        [priceLabel, noteLabel, buyButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            bottomCard.addSubview($0)
        }

        priceLabel.font = .boldSystemFont(ofSize: 20)
        noteLabel.font = .systemFont(ofSize: 13)
        noteLabel.textColor = .gray

        buyButton.setTitle("Купить", for: .normal)
        buyButton.backgroundColor = .systemGreen
        buyButton.setTitleColor(.white, for: .normal)
        buyButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        buyButton.layer.cornerRadius = 10
        buyButton.addTarget(self, action: #selector(openPayment), for: .touchUpInside)

        NSLayoutConstraint.activate([
            bottomCard.heightAnchor.constraint(equalToConstant: 80),
            bottomCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomCard.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            priceLabel.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor, constant: 16),
            priceLabel.topAnchor.constraint(equalTo: bottomCard.topAnchor, constant: 12),

            noteLabel.leadingAnchor.constraint(equalTo: priceLabel.leadingAnchor),
            noteLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 2),

            buyButton.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor, constant: -16),
            buyButton.centerYAnchor.constraint(equalTo: bottomCard.centerYAnchor),
            buyButton.widthAnchor.constraint(equalToConstant: 100),
            buyButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        bottomCard.isHidden = true
    }

    func updateBottomCard() {
        guard !selectedSeats.isEmpty else {
            bottomCard.isHidden = true
            return
        }
        bottomCard.isHidden = false
        let total = selectedSeats.map { $0.price }.reduce(0, +)
        priceLabel.text = "\(total) TJS"
        noteLabel.text = "за \(pluralForm(for: selectedSeats.count, word: "билет"))"
    }

    func pluralForm(for count: Int, word: String) -> String {
        let rem10 = count % 10
        let rem100 = count % 100

        if rem10 == 1 && rem100 != 11 {
            return "\(count) \(word)"
        } else if (2...4).contains(rem10) && !(12...14).contains(rem100) {
            return "\(count) \(word)а"
        } else {
            return "\(count) \(word)ов"
        }
    }

    @objc func openPayment() {
        let total = selectedSeats.map { $0.price }.reduce(0, +)
        let alert = UIAlertController(
            title: "Оплата",
            message: "Вы оплатили \(total) TJS за \(pluralForm(for: selectedSeats.count, word: "билет"))",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

extension ViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return schemeView
    }
}
