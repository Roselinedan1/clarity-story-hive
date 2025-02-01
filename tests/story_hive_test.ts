import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test story creation with category",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('story-hive', 'create-story', [
        types.ascii("Test Story"),
        types.bool(false),
        types.ascii("fantasy")
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(0);
    
    let getStory = chain.mineBlock([
      Tx.contractCall('story-hive', 'get-story', [
        types.uint(0)
      ], deployer.address)
    ]);
    
    const story = getStory.receipts[0].result.expectOk().expectSome();
    assertEquals(story['category'], "fantasy");
    assertEquals(story['reward-pool'], 0);
    assertEquals(story['likes'], 0);
  },
});

Clarinet.test({
  name: "Test story likes and reward pool",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    // Create story
    let block = chain.mineBlock([
      Tx.contractCall('story-hive', 'create-story', [
        types.ascii("Test Story"),
        types.bool(false),
        types.ascii("fantasy")
      ], deployer.address)
    ]);
    
    // Like story
    let likeStory = chain.mineBlock([
      Tx.contractCall('story-hive', 'like-story', [
        types.uint(0)
      ], user1.address)
    ]);
    
    likeStory.receipts[0].result.expectOk().expectBool(true);
    
    // Check likes and reward pool
    let getLikes = chain.mineBlock([
      Tx.contractCall('story-hive', 'get-story-likes', [
        types.uint(0)
      ], deployer.address)
    ]);
    
    let getRewards = chain.mineBlock([
      Tx.contractCall('story-hive', 'get-reward-pool', [
        types.uint(0)
      ], deployer.address)
    ]);
    
    getLikes.receipts[0].result.expectOk().expectUint(1);
    getRewards.receipts[0].result.expectOk().expectUint(10);
  },
});

Clarinet.test({
  name: "Test proposal rewards claiming",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    // Create story
    chain.mineBlock([
      Tx.contractCall('story-hive', 'create-story', [
        types.ascii("Test Story"),
        types.bool(false),
        types.ascii("fantasy")
      ], deployer.address)
    ]);
    
    // Submit and accept proposal
    let submitProposal = chain.mineBlock([
      Tx.contractCall('story-hive', 'submit-proposal', [
        types.uint(0),
        types.utf8("Test episode content")
      ], user1.address)
    ]);
    
    chain.mineBlock([
      Tx.contractCall('story-hive', 'accept-proposal', [
        types.uint(0)
      ], deployer.address)
    ]);
    
    // Like story to generate rewards
    chain.mineBlock([
      Tx.contractCall('story-hive', 'like-story', [
        types.uint(0)
      ], deployer.address)
    ]);
    
    // Claim rewards
    let claimRewards = chain.mineBlock([
      Tx.contractCall('story-hive', 'claim-proposal-rewards', [
        types.uint(0)
      ], user1.address)
    ]);
    
    claimRewards.receipts[0].result.expectOk().expectUint(10);
  },
});
