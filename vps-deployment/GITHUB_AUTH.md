# GitHub Container Registry Authentication

If you're pulling a private image from `ghcr.io`, you need to authenticate Docker with GitHub.

## Quick Setup

### 1. Create GitHub Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Give it a name like "Hummingbot VPS"
4. Select scope: **`read:packages`**
5. Click "Generate token"
6. **Copy the token** (you won't see it again!)

### 2. Option A: Deploy with Authentication

Set environment variables before running the deploy script:

```bash
export GITHUB_USERNAME="your_github_username"
export GITHUB_TOKEN="ghp_your_token_here"
cd vps-deployment
./deploy.sh
```

### 2. Option B: Manual Authentication on VPS

SSH into your VPS and authenticate manually:

```bash
ssh root@46.101.135.160

# Authenticate Docker with ghcr.io
echo "ghp_your_token_here" | docker login ghcr.io -u your_github_username --password-stdin

# Now you can pull the image
docker pull ghcr.io/skillsavers/hummingbot:latest
```

### 3. Option C: Using .env file

Create a `.env` file in the `vps-deployment` directory:

```bash
cp .env.example .env
# Edit .env and add your credentials
nano .env
```

Then source it before deploying:

```bash
source .env
./deploy.sh
```

## Verify Authentication

Check if you're logged in:

```bash
ssh root@46.101.135.160 'cat ~/.docker/config.json'
```

You should see `ghcr.io` in the list of auths.

## Troubleshooting

### "unauthorized" error

This means Docker isn't authenticated. Run:

```bash
ssh root@46.101.135.160
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin
```

### Token has expired

GitHub tokens can expire. Generate a new one and re-authenticate.

### Wrong permissions

Make sure your token has the `read:packages` scope. If not, create a new token with the correct scope.

## Security Notes

- Never commit your `.env` file with real credentials
- Use tokens with minimal required permissions
- Rotate tokens regularly
- Consider using GitHub Actions for automated deployments instead of storing tokens
