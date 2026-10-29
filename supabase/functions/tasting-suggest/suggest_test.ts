import { assertEquals } from 'jsr:@std/assert@1';

import { buildSystemPrompt, parseInput, sanitize } from './suggest.ts';

const input = { comment: 'x', vocabulary: ['후추', '바닐라'], colors: ['루비', '가넷'] };

Deno.test('sanitize keeps known attrs, clamps values, filters color', () => {
  const s = sanitize(
    {
      scores: [
        { attr: 'tannin', value: 6.6, evidence: '평균 이상' },
        { attr: 'body', value: 14, evidence: '끈적' },
        { attr: 'unknown', value: 3, evidence: '' },
      ],
      keywords: ['후추', '후추', ' 바닐라 ', ''],
      color: '루비',
    },
    input,
  );
  assertEquals(s.scores.tannin, { value: 7, evidence: '평균 이상' });
  assertEquals(s.scores.body?.value, 10);
  assertEquals(Object.keys(s.scores).length, 2);
  assertEquals(s.keywords, ['후추', '바닐라']);
  assertEquals(s.color, '루비');
  assertEquals(sanitize({ scores: [], keywords: [], color: '보라' }, input).color, '');
  assertEquals(sanitize(null, input), { scores: {}, keywords: [], color: '' });
});

Deno.test('parseInput validates the request body', () => {
  assertEquals(parseInput({}), 'comment is required');
  assertEquals(parseInput({ comment: 'a'.repeat(2001) }), 'comment is too long (max 2000)');
  const ok = parseInput({ comment: ' 좋음 ', vocabulary: ['후추'], colors: ['루비'] });
  assertEquals(typeof ok === 'object' && ok.comment, '좋음');
});

Deno.test('system prompt carries the vocabulary and colour lists', () => {
  const p = buildSystemPrompt(input);
  assertEquals(p.includes('후추, 바닐라'), true);
  assertEquals(p.includes('루비, 가넷'), true);
  assertEquals(p.includes('tannin'), true);
});
