from openai import OpenAI

# vLLM 서버 설정
client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="EMPTY"  # vLLM은 로컬 실행 시 API 키가 필요 없습니다.
)

# 모델 이름은 docker-compose.yml의 command에 설정된 것과 동일해야 합니다.
model_name = "/models/Qwen3-4B-Thinking-2507"

print(f"Model: {model_name} 에게 질문하는 중...")

try:
    completion = client.chat.completions.create(
        model=model_name,
        messages=[
            {"role": "system", "content": "You are a helpful AI coding assistant."},
            {"role": "user", "content": "C# 코딩에 대한 주석을 달아 줄 수 있어?"}
        ],
        temperature=0.7,
    )

    response_text = completion.choices[0].message.content

    # UTF-8로 파일에 저장
    with open("response.txt", "w", encoding="utf-8") as f:
        f.write(response_text)

    print("\n[답변이 response.txt 파일에 저장되었습니다]")
    print(f"응답 길이: {len(response_text)} 문자")

except Exception as e:
    print(f"에러 발생: {e}")
