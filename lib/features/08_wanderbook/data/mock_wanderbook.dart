/// A Wanderbook post: where it was taken and its caption.
class WanderPost {
  const WanderPost(this.location, this.caption);

  final String location;
  final String caption;
}

/// MOCK posts, the same as the website's. There is no Wanderbook API yet; replace with service calls.
const mockMyPosts = [
  WanderPost('Ibiza, Spain', 'Golden hour at Café del Mar.'),
  WanderPost('Lisbon, Portugal', 'Tram 28 and pastéis de nata.'),
  WanderPost('Amalfi, Italy', 'Lemon groves above the sea.'),
  WanderPost('Chefchaouen, Morocco', 'Lost in the blue streets.'),
  WanderPost('Cappadocia, Turkey', 'Up before sunrise for the balloons.'),
  WanderPost('Hallstatt, Austria', 'A postcard come to life.'),
];

const mockFeedPosts = [
  WanderPost('Queenstown, New Zealand', 'Bungee first, coffee second.'),
  WanderPost('Hoi An, Vietnam', 'Lantern night on the river.'),
  WanderPost('Banff, Canada', 'Lake Moraine is unreal.'),
  WanderPost('Cusco, Peru', 'Acclimatising before the Inca Trail.'),
  WanderPost('Zanzibar, Tanzania', 'Spice tour and a dhow sunset.'),
  WanderPost('Edinburgh, Scotland', 'Arthur’s Seat in the drizzle.'),
];
