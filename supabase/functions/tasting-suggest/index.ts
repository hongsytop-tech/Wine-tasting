// 테이스팅 메모(총평) → 점수·키워드·색상 제안. 앱은 제안을 보여주고 사용자가
// 고른 것만 적용한다 (자동 저장 없음).
//
// 요청: POST { comment, vocabulary: string[], colors: string[] }  (로그인 사용자만)
// 응답: { scores: {attr: {value, evidence}}, keywords: string[], color: string }
// 필요한 secret: ANTHROPIC_API_KEY

import Anthropic from 'npm:@anthropic-ai/sdk@^1.3.0';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';
import { buildSystemPrompt, OUTPUT_SCHEMA, parseInput, sanitize } from './suggest.ts';

const MODEL = 'claude-opus-5-5';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'POST only' }, 405);

  // 비용이 드는 호출이므로 로그인한 사용자만 허용 (anon 키만으로는 불가).
  const user = await currentUser(req);
  if (!user) return json({ error: 'login_required' }, 401);

  const apiKey = Deno.env.get('ANTHROPIC_API_KEY') ?? '';
  if (!apiKey) {
    return json(
      { error: 'no_api_key', detail: 'Supabase secret ANTHROPIC_API_KEY 가 필요합니다.' },
      500,
    );
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'invalid JSON' }, 400);
  }
  const input = parseInput(body);
  if (typeof input === 'string') return json({ error: input }, 400);

  try {
    const client = new Anthropic({ apiKey });
    const response = await client.beta.messages.create({
      model: MODEL,
      max_tokens: 4000,
      // 짧은 추출 작업이라 낮은 effort 로 충분.
      output_config: {
        effort: 'low',
        format: { type: 'json_schema', schema: OUTPUT_SCHEMA },
      },
      // 안전 분류기가 요청을 거절하면 권장 모델로 서버에서 다시 실행.
      betas: ['server-side-fallback-2026-07-01'],
      fallbacks: 'default',
      system: buildSystemPrompt(input),
      messages: [{ role: 'user', content: input.comment }],
    });

    if (response.stop_reason === 'refusal') {
      return json({ error: 'refusal' }, 422);
    }
    const text = response.content
      .filter((b) => b.type === 'text')
      .map((b) => (b as { text: string }).text)
      .join('');
    let raw: unknown;
    try {
      raw = JSON.parse(text);
    } catch {
      return json({ error: 'bad_model_output' }, 502);
    }
    return json(sanitize(raw, input));
  } catch (e) {
    if (e instanceof Anthropic.RateLimitError) return json({ error: 'rate_limited' }, 429);
    if (e instanceof Anthropic.AuthenticationError) {
      return json({ error: 'bad_api_key', detail: 'ANTHROPIC_API_KEY 가 올바르지 않습니다.' }, 500);
    }
    if (e instanceof Anthropic.APIError) {
      console.error('anthropic error', e.status, e.message);
      return json({ error: `anthropic_${e.status}`, detail: e.message.slice(0, 200) }, 502);
    }
    console.error('unhandled', e);
    return json({ error: String(e) }, 500);
  }
});

async function currentUser(req: Request) {
  const auth = req.headers.get('Authorization') ?? '';
  if (!auth) return null;
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: auth } }, auth: { persistSession: false } },
  );
  const { data } = await supabase.auth.getUser();
  return data.user ?? null;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
