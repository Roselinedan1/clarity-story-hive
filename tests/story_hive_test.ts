// [Previous imports and tests remain unchanged]

Clarinet.test({
  name: "Test story status management",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Create story
    let block = chain.mineBlock([
      Tx.contractCall('story-hive', 'create-story', [
        types.ascii("Test Story"),
        types.bool(false),
        types.ascii("fantasy")
      ], deployer.address)
    ]);
    
    // Complete story
    let completeStory = chain.mineBlock([
      Tx.contractCall('story-hive', 'complete-story', [
        types.uint(0)
      ], deployer.address)
    ]);
    
    completeStory.receipts[0].result.expectOk().expectBool(true);
    
    // Check status
    let getStatus = chain.mineBlock([
      Tx.contractCall('story-hive', 'get-story-status', [
        types.uint(0)
      ], deployer.address)
    ]);
    
    getStatus.receipts[0].result.expectOk().expectAscii("completed");
  },
});
