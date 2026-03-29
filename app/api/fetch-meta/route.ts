import { NextRequest, NextResponse } from 'next/server';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const url = searchParams.get('url');
  if (!url) return NextResponse.json({ error: 'No url' }, { status: 400 });

  // Fallback jika API key tidak tersedia
  return NextResponse.json({
    title: 'Link',
    description: 'Shared link',
    icon: '',
    ogImage: '',
  });
}
