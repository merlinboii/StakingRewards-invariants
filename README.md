# Foundry StakingRewards

Fuzz with:

```bash
echidna . --contract CryticTester --config echidna.yaml --format text --workers 16 --test-limit 1000000
recon fuzz . --contract CryticTester --config echidna.yaml --format text --workers 16 --test-limit 1000000000
medusa fuzz
```

Goals:
- Reach full coverage
- Property Specification
- Property Implementation