import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ideas_app/features/ideas/presentation/ideas_page.dart';
import 'package:ideas_app/features/ideas/presentation/idea_detail_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'ideas',
      builder: (context, state) => const IdeasPage(),
    ),
    GoRoute(
      path: '/idea/:id',
      name: 'idea-detail',
      builder: (context, state) {
        final ideaId = state.pathParameters['id']!;
        return IdeaDetailPage(ideaId: ideaId);
      },
    ),
  ],
);