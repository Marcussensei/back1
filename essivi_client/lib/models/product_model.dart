class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String image;
  final int stock;
  final double rating;
  final int reviews;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.image,
    required this.stock,
    required this.rating,
    required this.reviews,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      image: json['image'] ?? '',
      stock: json['stock'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      reviews: json['reviews'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image': image,
      'stock': stock,
      'rating': rating,
      'reviews': reviews,
    };
  }
}
