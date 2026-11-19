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

## 그래픽
- 기본은 `SOFT`(부드러운 3D: softPerson/softDuck, 둥근 나무, 스터드 없는 바닥). 메뉴에서 블록(로블록스) 스타일로 전환, localStorage `duck-farm-v1-style`.

## 테스트
- Playwright 크로미움: `--use-gl=angle --use-angle=swiftshader --enable-unsafe-swiftshader --ignore-gpu-blocklist`, three.min.js는 로컬 npm 사본으로 route, 폰트 abort. `?fast=2`면 `window.__farm` 디버그 훅(go, setY, walk, simCourse, simPath, closetCard, addRes, setDay 등).
- 수정 후 `<script>` 블록 문법 검사(new Function) → 스크린샷 → 커밋.
