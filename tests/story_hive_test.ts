import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test story creation and retrieval",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('story-hive', 'create-story', [
        types.ascii("Test Story"),
        types.bool(false)
      ], deployer.address)
    ]);
    
    // Verify story creation
    block.receipts[0].result.expectOk().expectUint(0);
    
    // Get story details
    let getStory = chain.mineBlock([
      Tx.contractCall('story-hive', 'get-story', [
        types.uint(0)
      ], deployer.address)
    ]);
    
    const story = getStory.receipts[0].result.expectOk().expectSome();
    assertEquals(story['title'], "Test Story");
    assertEquals(story['creator'], deployer.address);
    assertEquals(story['episode-count'], 0);
    assertEquals(story['premium'], false);
  },
});

Clarinet.test({
  name: "Test proposal submission and voting",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    // Create story
    let block = chain.mineBlock([
      Tx.contractCall('story-hive', 'create-story', [
        types.ascii("Test Story"),
        types.bool(false)
      ], deployer.address)
    ]);
    
    // Submit proposal
    let submitProposal = chain.mineBlock([
      Tx.contractCall('story-hive', 'submit-proposal', [
        types.uint(0),
        types.utf8("Test episode content")
      ], user1.address)
    ]);
    
    submitProposal.receipts[0].result.expectOk().expectUint(0);
    
    // Vote on proposal
    let voteProposal = chain.mineBlock([
      Tx.contractCall('story-hive', 'vote-proposal', [
        types.uint(0)
      ], deployer.address)
    ]);
    
    voteProposal.receipts[0].result.expectOk().expectBool(true);
    
    // Get proposal details
    let getProposal = chain.mineBlock([
      Tx.contractCall('story-hive', 'get-proposal', [
        types.uint(0)
      ], deployer.address)
    ]);
    
    const proposal = getProposal.receipts[0].result.expectOk().expectSome();
    assertEquals(proposal['votes'], 1);
    assertEquals(proposal['status'], "pending");
  },
});

Clarinet.test({
  name: "Test premium story access",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    // Create premium story
    let block = chain.mineBlock([
      Tx.contractCall('story-hive', 'create-story', [
        types.ascii("Premium Story"),
        types.bool(true)
      ], deployer.address)
    ]);
    
    // Purchase access
    let purchase = chain.mineBlock([
      Tx.contractCall('story-hive', 'purchase-access', [
        types.uint(0)
      ], user1.address)
    ]);
    
    purchase.receipts[0].result.expectOk().expectBool(true);
    
    // Check access
    let checkAccess = chain.mineBlock([
      Tx.contractCall('story-hive', 'check-story-access', [
        types.uint(0),
        types.principal(user1.address)
      ], deployer.address)
    ]);
    
    checkAccess.receipts[0].result.expectOk().expectBool(true);
  },
});