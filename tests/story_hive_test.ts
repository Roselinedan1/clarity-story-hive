// [Previous test content with added security test cases]

Clarinet.test({
  name: "Test contract pause functionality",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user = accounts.get('wallet_1')!;
    
    // Test pause
    let pause = chain.mineBlock([
      Tx.contractCall('story-hive', 'toggle-contract-pause', [], deployer.address)
    ]);
    pause.receipts[0].result.expectOk().expectBool(true);
    
    // Test create story while paused
    let createStory = chain.mineBlock([
      Tx.contractCall('story-hive', 'create-story', [
        types.ascii("Test Story"),
        types.bool(false),
        types.ascii("fantasy")
      ], user.address)
    ]);
    createStory.receipts[0].result.expectErr().expectUint(109);
  }
});

[... additional test cases for new features ...]
