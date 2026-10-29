// 총평 글 → 특징 점수·키워드·색상 제안 (순수 로직: 프롬프트·스키마·응답 정리).
// 네트워크 호출은 index.ts 에서 한다.

/** 앱(Dart TasteAttr)과 같은 이름. */
export const ATTRS = [
  'colorIntensity',
  'aromaIntensity',
  'sweetness',
  'acidity',
  'tannin',
  'alcohol',
  'body',
  'finish',
] as const;
export type Attr = (typeof ATTRS)[number];

const ATTR_GUIDE: Record<Attr, string> = {
  colorIntensity: '색의 진하기 (0 옅음 ~ 10 진함)',
  aromaIntensity: '향의 강도 (0 약함 ~ 10 강함)',
  sweetness: '당도 (0 드라이 ~ 10 스위트)',
  acidity: '산미 (0 낮음 ~ 10 높음)',
  tannin: '타닌 (0 낮음 ~ 10 높음)',
  alcohol: '알코올감 (0 낮음 ~ 10 높음)',
  body: '바디·질감·점도 (0 가벼움 ~ 10 무거움)',
  finish: '여운 길이 (0 짧음 ~ 10 긺)',
};

export interface SuggestInput {
  comment: string;
  /** 앱의 향·맛 묘사어 목록 (이 중에서 고르도록 유도). */
  vocabulary: string[];
  /** 와인 종류에 맞는 색상 이름 목록. */
  colors: string[];
}

export interface Suggestion {
  scores: Partial<Record<Attr, { value: number; evidence: string }>>;
  keywords: string[];
  color: string;
}

/** 구조화 출력 스키마 — 글에 언급된 특징만 scores 배열에 담게 한다. */
export const OUTPUT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['scores', 'keywords', 'color'],
  properties: {
    scores: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['attr', 'value', 'evidence'],
        properties: {
          attr: { type: 'string', enum: [...ATTRS] },
          value: { type: 'integer' },
          evidence: { type: 'string' },
        },
      },
    },
    keywords: { type: 'array', items: { type: 'string' } },
    color: { type: 'string' },
  },
} as const;

export function buildSystemPrompt(input: SuggestInput): string {
  const attrs = ATTRS.map((a) => `- ${a}: ${ATTR_GUIDE[a]}`).join('\n');
  return [
    '너는 사용자가 한국어로 쓴 와인 테이스팅 메모를 정해진 기록 항목으로 옮기는 도우미다.',
    '메모에 실제로 적힌 내용만 옮긴다. 적혀 있지 않은 항목은 비워 둔다 — 품종·산지에 대한',
    '일반 지식으로 짐작해 채우지 않는다.',
    '',
    '[scores] 메모에서 언급된 특징만, 0~10 정수로. 항목:',
    attrs,
    '정도 표현은 대략 이렇게 옮긴다: 매우 낮음 1, 낮음 2~3, 중간 5, 평균 이상·중간 이상 6~7,',
    '높음 8, 매우 높음 9~10. evidence 에는 근거가 된 메모 구절을 그대로 짧게 인용한다.',
    '',
    '[keywords] 메모에 나온 향·맛 묘사어. 아래 목록에 같은 뜻의 단어가 있으면 목록의 표기를',
    '쓰고, 없으면 메모의 표현을 짧은 명사로 쓴다. 메모에 없는 묘사어는 넣지 않는다.',
    `목록: ${input.vocabulary.join(', ')}`,
    '',
    '[color] 메모에 색상이 적혀 있으면 아래 목록 중 가장 가까운 하나, 없으면 빈 문자열.',
    `목록: ${input.colors.join(', ')}`,
  ].join('\n');
}

/** 모델 출력 정리: 알 수 없는 항목·범위 밖 값 제거, 중복·과다 키워드 정리. */
export function sanitize(raw: unknown, input: SuggestInput): Suggestion {
  const out: Suggestion = { scores: {}, keywords: [], color: '' };
  if (!raw || typeof raw !== 'object') return out;
  const r = raw as Record<string, unknown>;
  for (const s of Array.isArray(r.scores) ? r.scores : []) {
    if (!s || typeof s !== 'object') continue;
    const { attr, value, evidence } = s as Record<string, unknown>;
    if (!ATTRS.includes(attr as Attr) || typeof value !== 'number') continue;
    out.scores[attr as Attr] = {
      value: Math.max(0, Math.min(10, Math.round(value))),
      evidence: String(evidence ?? '').slice(0, 120),
    };
  }
  const seen = new Set<string>();
  for (const k of Array.isArray(r.keywords) ? r.keywords : []) {
    const t = String(k).trim().slice(0, 20);
    if (t && !seen.has(t)) {
      seen.add(t);
      out.keywords.push(t);
    }
  }
  out.keywords = out.keywords.slice(0, 15);
  const color = String(r.color ?? '').trim();
  out.color = input.colors.includes(color) ? color : '';
  return out;
}

/** 요청 본문 검사. 문제가 있으면 오류 문구. */
export function parseInput(body: unknown): SuggestInput | string {
  if (!body || typeof body !== 'object') return 'invalid body';
  const b = body as Record<string, unknown>;
  const comment = String(b.comment ?? '').trim();
  if (!comment) return 'comment is required';
  if (comment.length > 2000) return 'comment is too long (max 2000)';
  const list = (v: unknown, max: number) =>
    (Array.isArray(v) ? v : []).map((x) => String(x).slice(0, 30)).slice(0, max);
  return { comment, vocabulary: list(b.vocabulary, 200), colors: list(b.colors, 20) };
}
