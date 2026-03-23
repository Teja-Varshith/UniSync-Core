
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/features/peer_connect/peers/peer_repository.dart';
import 'package:UniSync/models/peer_model.dart';

final PeerControllerProvider = StateNotifierProvider<PeerController,bool>((ref) {
  return PeerController(PeerRepository: ref.read(PeerRepositoryProvider), ref: ref);
});

class PeerController extends StateNotifier<bool>{
  final PeerRepository _peerRepository;
  final Ref _ref;

  PeerController({
    required PeerRepository PeerRepository,
    required Ref ref,
  }) : _peerRepository = PeerRepository , _ref = ref, super(false);

  Future<PeerModel?> getMyPeerCard(String userId) async{
    try {
  final m = await _peerRepository.getPeerCard(userId);
  return m;
}catch (e) {
  return null;
}
  }

   // ── Toggle like (like if not liked, unlike if already liked) ──────────────
  // Returns the NEW liked state (true = now liked)
  Future<bool> toggleLike({
    required String cardOwnerId,
    required String currentUserId,
  }) async {
    // Self-like guard — controller enforces this, not just UI
    if (cardOwnerId == currentUserId) {
      throw Exception('Cannot like your own card');
    }
 
    try {
      final alreadyLiked = await _peerRepository.hasLiked(cardOwnerId, currentUserId);
      if (alreadyLiked) {
        await _peerRepository.unlikeCard(cardOwnerId, currentUserId);
        return false;
      } else {
        await _peerRepository.likeCard(cardOwnerId, currentUserId);
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }
 
  // ── Get like count for a card ──────────────────────────────────────────────
  Future<int> getLikeCount(String cardOwnerId) async {
    try {
      final peer = await _peerRepository.getPeerCard(cardOwnerId);
      return peer.likedBy.length;
    } catch (e) {
      return 0;
    }
  } 


  Future<void> createPeerCard(PeerModel peer,String userId) async{
    await _peerRepository.createPeerCard(peer,userId);
  }

  Future<void> getAllAvailableTraits() async{
    await _peerRepository.getAllPublicPeers();
  }

   Future<List<PeerModel>> getAllPublicPeers() async{
    return await _peerRepository.getAllPublicPeers();
  }

  //  Future<void> getFilteredPeers() async{
  //   await _peerRepository.ge();
  // }



}