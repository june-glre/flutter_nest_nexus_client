#!/bin/bash
# openapi-generator를 사용해 lib/generated/ 폴더를 재생성하는 스크립트.
#
# 사전 요구사항:
#   brew install openapi-generator  # macOS
#   npm install -g @openapitools/openapi-generator-cli  # npm
#
# 사용법:
#   ./scripts/generate.sh https://your-api.com/api-json
#   ./scripts/generate.sh http://localhost:3000/api-json  # 로컬 NestJS 서버
#
# NestJS Swagger 설정:
#   app.useGlobalPrefix('api');
#   const config = new DocumentBuilder().setTitle('API').build();
#   const document = SwaggerModule.createDocument(app, config);
#   SwaggerModule.setup('api', app, document);
#   → Swagger JSON URL: http://localhost:3000/api-json

set -e

SPEC_URL=${1:-"http://localhost:3000/api-json"}
OUTPUT_DIR="lib/generated"

echo "Generating Dart client from: $SPEC_URL"
echo "Output directory: $OUTPUT_DIR"

# 기존 generated 폴더 백업
if [ -d "$OUTPUT_DIR" ]; then
  echo "Backing up existing generated/ to .generated_backup/"
  cp -r "$OUTPUT_DIR" ".generated_backup"
fi

openapi-generator generate \
  -i "$SPEC_URL" \
  -g dart-dio \
  -o "$OUTPUT_DIR" \
  --additional-properties=pubName=flutter_nest_nexus_client \
  --additional-properties=pubVersion=0.0.1

echo ""
echo "Generation complete. Running build_runner..."
dart run build_runner build --delete-conflicting-outputs

echo ""
echo "Done! Now update lib/modules/ wrappers if new endpoints were added."
