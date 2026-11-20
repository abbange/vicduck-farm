# 오리 농장 (duck farm) — 작업 인수인계

딸(11세)을 위한 오프라인·싱글플레이 로블록스풍 오리 농장 게임. 부모(사용자)는 한국어로 짧고 정확한 답을 선호하고, 바뀐 화면은 스크린샷으로 보여 주길 원함. 온라인 친구/채팅/현금결제 기능은 넣지 않음.

## 파일과 배포
- 개발 원본: `abbange/duck` 저장소 `farm/index.html` (단일 HTML, Three.js r128 cdnjs). 작업 브랜치 `claude/cool-fermat-g9k93r`.
- 공개 배포: `abbange/vicduck-farm` 저장소 `main` 브랜치 루트 `index.html` → GitHub Pages https://abbange.github.io/vicduck-farm/ (로그인 불필요, 아이가 실제로 쓰는 주소).
- 배포 절차(중간 점검 후 배포):
  1. `farm/index.html` 수정 → 테스트·스크린샷 → duck 브랜치에 커밋/푸시.
  2. 같은 파일을 vicduck-farm `preview.html`로 복사해 main에 푸시 → 부모님 미리보기 https://abbange.github.io/vicduck-farm/preview.html (부모가 직접 해 보고 확인).
  3. 부모가 "올려줘"라고 하면 그때 vicduck-farm `index.html`에도 복사해 푸시(아이 주소). 부모가 처음부터 "배포까지 해줘"라고 한 경우에만 바로 index.html까지 올림.
- 미리보기(`PREVIEW`, 파일명이 preview.html이거나 `?preview`): localStorage 키 `duck-farm-preview`를 따로 쓰고 Supabase 클라우드를 끔 → 아이 저장·가족 클라우드와 섞이지 않음. 화면 아래 🛠 테스트 도구(코인, 밤/낮, 침입자 부르기, 물총 단계).
- 예전 Claude 아티팩트(https://claude.ai/artifact/M6DzcvxAAjGKREt9rhUFbY, db capability)도 있으나 이제 보조. 옛 버전 루트 `index.html`(2D), `3d/`, `preview/`는 쓰지 않음.

## 서버 (Supabase)
- 프로젝트 `duck-farm`, id `njucveeybhgzuoavhurk` (서울, 유료 조직). URL/publishable key는 index.html의 `const SB=`.
- 스키마 `duckfarm`: `families(code)`, `docs(code,key,val)`, `results(code,rec,at)`. RLS on + 정책 없음 → 표 직접 접근 불가. `public.df_*` security definer 함수로만 접근(가족 코드가 비밀키 역할). 원본 SQL: `farm/supabase/schema.sql`.
- docs key: `save/main`(게임 저장), `homework/current`, `vocab/current`, `vocab/stats`.
- 게임은 가족 코드가 있으면 Supabase, 없으면 Claude 아티팩트 db를 씀(`openDB()`). onSnapshot은 30초 폴링.

### 숙제 넣기 (부모가 숙제 사진/글을 보내면)
1. 문제를 게임 형식으로 변환. 형식(parseHW): `# 그룹 제목`, `단어: apple = 사과`, `고르기: 문장 = 정답`, `빈칸: ___ 문장 = 정답`, `쓰기: 질문 = 정답` (정답에 `a|b` 복수 허용, 범위 `2.45<=x<2.55`, 두 개 쓰기 `x2`). 사실관계는 반드시 검증하고 의심스러우면 부모에게 표시.
2. items 배열로 넣기: 단어 `{type:'word',en,ko,g,title}`, 그 외 `{type:'choose'|'blank'|'write',q,a,g,title}` (g=그룹 번호, title=그룹 제목).
3. 가족 코드 확인: `select code, created_at from duckfarm.families;` (가족이 여럿이면 부모에게 확인)
4. 넣기: `select public.df_set('<code>','homework/current', jsonb_build_object('hw', jsonb_build_object('id', (extract(epoch from now())*1000)::bigint, 'items', '<items json>'::jsonb, 'reward', 50), 'every', 20, 'at', now()));`
5. 아이 기기에 30초 안에 "새 숙제가 도착했어요" 표시. 숙제는 아이 집 공부방 책상에서만 풂.
- 결과 보기: `select rec, at from duckfarm.results where code='<code>' order by at desc limit 20;`
- 단어장: `vocab/current` = `{vocab:{id, words:[{en,ko}]}}` 형태(코드의 vocabEditor 참고).

## 만든 목적과 방향 (부모님 설명)
- 딸: 국제학교 5학년. 로블록스에서 어울리는 친구들과 자연스레 멀어지도록, 혼자서도 오래 재미있게 노는 게임으로 관심을 돌리려는 목적.
- 영어 학습 효과를 최대로: 중요한 순간마다 영어 대사(음성 + 화면에 "영어 · 한국어"), 이웃 대화·부탁도 영어. 한자 단어는 읽어 주지 않음.
- 진행 방식: 수정 → 미리보기(preview.html) → 부모가 "올려줘" 하면 index.html. 응답은 짧게, 바뀐 화면은 스크린샷으로.

## 기능 지도 (farm/index.html, 2026-11 기준)
- 농장: 밀밭·방앗간·급식기·물통·둥지·부화기(희귀 품종 먼저)·알 가게·오리집(작은→큰→궁전, 안에 들어가기)·땅 넓히기(1.35배 값, 넓히기 보상, 땅마다 미니 도전 코스)·개울(이어 놓기, 다리)·장식(분수·정자·그네·해바라기·수국·피크닉 등).
- 오리: 품종 9종(페킨·러너·콜덕·머스코비·카키캠벨·크레스티드·루앙·거위·청둥오리 손님), 이름·성격 6종·애정 0~10·기분 말풍선·아기가 엄마 따라감.
- 동물 친구: 강아지(따라옴·침입자에게 짖음·묘기·옷), 닭장(품종 3·달걀), 벌통(꽃 근처 꿀), 물가·풀밭 도감(12종), 연못 낚시, 요리(꿀빵·팬케이크).
- 침입자: 까마귀·너구리·고양이·늑대 / 박수·💦물총(4단계, 자동 조준)·거위·강아지가 도움 / 빨간 고리·화면 테두리 깜빡임·화면 밖 화살표.
- 도전 코스: 1 계단, 2~4는 날마다 새 모양(점프 가능 검사, 실패 시 원래 코스)·테마 4종·⏱기록과 ⭐·💎숨은 보석·🔑지식 열쇠 문·보석 탑 미끄럼틀.
- 마을(x=VX=90): 이웃 6명(할머니·민준·시장·하린·수아 언니·낚시 할아버지), 영어 부탁·이야기 부탁 2단계·집 안 구경·친구 수첩·농장 방문, 계절마다 7일째 축제, 시장.
- 집 방: 넓은 방, 인형 22종·30자리(➕ 직접 눌러 놓기), 벽지·바닥, 요리, 공부방 책상 숙제.
- 날씨·자연: 날마다 날씨(비·눈), 비 갠 오후 무지개, 밤하늘 북두칠성+계절 별자리.
- 공부: 숙제(Supabase), 황금 물건 단어 문제(55%), 받아쓰기·단어 퍼즐, 문지기/보물상자 수학·영어 문제, 숙제 연속 보상(3·5·7·10·14·30일).
- 🎙️ 원어민 녹음: ElevenLabs(eleven_v4)로 만든 영어 대사 108개가 `vo/<md5 앞 10자>.mp3`(배포 저장소 루트 vo/, duck은 farm/vo/). 코드의 `const VO={문장:id}`. 목소리: 나=Remi(bnTR7KqyVKMHBsS2Dt4z), 할머니=Gramma Sherry, 민준=Sheldon, 시장=Jesse, 하린=Kymmiee, 수아=Bree, 낚시=Noah. 새 대사를 추가하면 녹음해 VO에 넣어야 원어민 발음(없으면 기기 TTS). 여러 문장을 [long pause]로 이어 한 번에 녹음 → ffmpeg silencedetect로 잘라 씀. elevenlabsusercontent.com은 duck 환경 허용 호스트에 추가됨.
- 소리: 배경음악 11곡(아침·농장·오후·비·겨울·밤·마을·축제·모험·방·아늑), 효과음 SFX 객체, 영어 대사 line(en,ko) — ☰ 메뉴에서 영어 음성 끄기/켜기.
- 미리보기 🛠 테스트 도구, 부모님 메뉴(PIN), 가족 코드 클라우드 저장.

## 작업 습관 (다음 세션용)
- 같은 파일을 다른 작업 창에서 동시에 고치면 덮어쓸 위험. vicduck-farm main에 다른 커밋이 있으면 3방향 병합(git merge-file) 후 올림.
- 테스트 스크립트 패턴: `window.__farm.gun("()=>{...}")`로 내부 함수 직접 호출(?fast=2일 때만). 도전 코스는 60일치 점프 시뮬레이션으로 확인.
- 새 자원(RES)을 추가하면 WHERE(얻는 곳 안내)에도 추가해야 함(없으면 상점이 멈췄던 적 있음).

## 가족 플레이어·방문 (1119d)
- `WHO`(localStorage `<KEYBASE>-who`: kid/mom/dad)로 플레이어별 저장(`KEY`=KEYBASE+'-mom' 등, 클라우드 `save/mom`·`save/dad`). 게임을 열면 로그인 화면(👧·👩·👨, 엄마·아빠는 각자 PIN `<KEYBASE>-pin-<who>`), ☰ 메뉴 → 👤 플레이어 바꾸기. 같은 탭 새로고침은 sessionStorage로 다시 안 물음. 엄마·아빠는 숙제 알림/수신 꺼짐.
- 마을 버스 정류장 옆 🏡 가족 농장 표지판 → `?visit=<who>`로 상대 농장 구경(저장 안 함, 짓기·상점 막음). 🎁 선물·📝 영어 방명록은 `gift/<who>` 문서, 받는 쪽이 다음 접속 때 받음. 미리보기에선 localStorage로 대신함.
- 새 동물: 🐷 돼지우리(버섯)·🐑 양 우리(양털 깎기)·🐐 염소 우리(염소젖)·🐰 토끼장(거름 → 밀밭 즉시 성장). `PENS`, `petsTick`, `petsNewDay`, 짓기 🐾 동물 탭.

## 경영 모드 1단계 (1120c)
- 🗺️ 계획 모드(`PLAN`, HUD 🗺️): 하늘 카메라(planC/planD, 끌어 이동·핀치/휠 확대), 건물 위 이모지 라벨, 칸을 톡 누르면 바로 짓기(연속), 빈 밭 한꺼번에 심기·모두 거두기.
- 작물 6종 `CROPS`(밀·옥수수·당근·호박·해바라기·딸기): 씨앗 값, 계절 배율 `ss[sIdx]`, 넓은 밭은 같은 작물 자동 재파종. 새 RES corn/carrot/pumpkin/sunf/berry(+WHERE).
- 📈 시세판(HUD 📈, `marketBoard`): `priceOf(k,day)` 날짜로 정해지는 값(파동+잡음+비제철 가산), 7일 그래프, 두 번 눌러 팔기.
- 2단계(1120d) 가공 공방 `WK`: 빵집(밀3→빵)·치즈 공방(염소젖2→치즈)·털실 공방(양털2→목도리)·잼 공방(딸기3→잼)·파이 가게(호박1+밀2→파이). 재료가 창고에 있으면 `wkTick`이 저절로 생산(밀은 4개 남김), ⏸ 쉬기 토글, 굴뚝 연기. 동물 우리 생산물은 창고(RES mush/wool/milk)로. 시세판 탭 🌽작물·🐾동물·🏭가공품 + 🔗 생산 사슬 카드. 값 `PBASE`.
- 3단계(1120e) 마을 성장 `townS()`(S.town): 🏡 주민 집(cottage, 방 2/3/4), 행복도 `happyParts`(기본20+꾸미기≤40+가게·공방≤20+개울≤8+주문≤20), 다음 날 행복도≥35+주민×3이고 빈 방 있으면 이사(영어 이름), 주민이 농장 돌아다님, 매일 주문(영어 문장)·전달 보상, 마을 기금, `townNewDay`가 📰 Duck Village Daily(영어+한국어, 🔊). HUD 🏘️ 마을 관리.
- 🎲 오늘의 마을 이야기(1121a) `S.story`, `storyNewDay`(날짜 시드, 매일 3개): ①장소(🍾 병 편지 영어 수수께끼 `RIDDLES` / 🐥 길 잃은 아기 오리 "next to/behind/in front of the bakery" 찾기 `PLACES`·`PREPS` / 🧳 떠돌이 상인 영어 곱셈 문제) ②주민(❗ `NEEDS` 추론·`SOCIAL` 상황 표현) ③🏆 하루 도전 영어 지시문 `CHAL`(카운터 증가로 판정). `choiceCard`는 🔊 읽기·🇰🇷 뜻 보기·결과를 results에 kind:'story'로 기록. 신문 첫 기사로 나옴. 📘 영어 연속 일수 `engS()`(HUD 칩). 해결 시 행복도 보너스 `T2.bonus`.

## 그래픽
- 기본은 `SOFT`(부드러운 3D: softPerson/softDuck, 둥근 나무, 스터드 없는 바닥). 메뉴에서 블록(로블록스) 스타일로 전환, localStorage `duck-farm-v1-style`.

## 테스트
- Playwright 크로미움: `--use-gl=angle --use-angle=swiftshader --enable-unsafe-swiftshader --ignore-gpu-blocklist`, three.min.js는 로컬 npm 사본으로 route, 폰트 abort. `?fast=2`면 `window.__farm` 디버그 훅(go, setY, walk, simCourse, simPath, closetCard, addRes, setDay 등).
- 수정 후 `<script>` 블록 문법 검사(new Function) → 스크린샷 → 커밋.

## 가족 놀이 (1121c)
- 주(월요일 시작, `weekKey()`)마다 새로. 문서 `fam/coop`·`fam/contest`(Supabase docs key 허용 목록에 추가됨, 미리보기는 localStorage).
- 🤝 가족 목표 `COOP`(달걀·수확·공방·주문·침입자·영어 정답 `engok`·부화): 각자 이번 주 `S.cnt` 증가분(`S.coop.base`)을 `prog[who]`로 올림, 합이 목표에 닿으면 각자 한 번 🪙80 ✨2. `coopSync` 60초마다.
- 🏆 꾸미기 대회: 방문 중 ⭐ 별 주기(`voteCard`, 1~3개 + 영어 칭찬), 별 합계 → 같으면 `decoScore`. 다음 주 첫 접속 때 `last`로 넘기고 결과 카드(우승 🪙120 ✨3, 참가 🪙40, `S.contGot`).
- 허브 `famHubCard`: 마을 👪 표지판, 🏘️ 마을 관리 버튼.
- 주의: 오늘의 이야기는 `S.dstory`(예전 `S.story`는 이웃 이야기 부탁 단계 수와 겹쳐서 분리함).
