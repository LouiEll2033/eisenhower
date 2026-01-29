import streamlit as st
from datetime import datetime, timedelta
import json
import os

# 페이지 설정
st.set_page_config(
    page_title="아이젠하워 매트릭스 플래너",
    page_icon="📋",
    layout="wide"
)

# CSS 스타일
st.markdown("""
<style>
    @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;700&display=swap');
    
    * {
        font-family: 'Noto Sans KR', sans-serif;
    }
    
    .main {
        background-color: #f3f4f6;
    }
    
    .quadrant-box {
        padding: 1.5rem;
        border-radius: 1rem;
        border: 2px solid;
        min-height: 300px;
        margin-bottom: 1rem;
    }
    
    .quadrant-1 {
        background-color: #FFCDD2;
        border-color: #FFCDD2;
    }
    
    .quadrant-2 {
        background-color: #C8E6C9;
        border-color: #C8E6C9;
    }
    
    .quadrant-3 {
        background-color: #FFF9C4;
        border-color: #FFF9C4;
    }
    
    .quadrant-4 {
        background-color: #E0E0E0;
        border-color: #E0E0E0;
    }
    
    .task-item {
        background-color: white;
        padding: 0.75rem;
        border-radius: 0.5rem;
        margin-bottom: 0.5rem;
        border: 1px solid rgba(0,0,0,0.05);
        box-shadow: 0 1px 2px rgba(0,0,0,0.05);
    }
    
    .task-completed {
        text-decoration: line-through;
        opacity: 0.6;
        color: #9CA3AF;
    }
    
    .stButton>button {
        width: 100%;
        background-color: #1E3A8A;
        color: white;
        border-radius: 0.5rem;
        padding: 0.5rem;
        font-weight: bold;
        border: none;
    }
    
    .stButton>button:hover {
        background-color: #1E40AF;
    }
    
    h1, h2, h3 {
        font-family: 'Noto Sans KR', sans-serif !important;
    }
</style>
""", unsafe_allow_html=True)

# 데이터 파일 경로
DATA_FILE = "tasks_data.json"

# 세션 스테이트 초기화
if 'current_date' not in st.session_state:
    st.session_state.current_date = datetime.now().date()

if 'tasks' not in st.session_state:
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r', encoding='utf-8') as f:
            st.session_state.tasks = json.load(f)
    else:
        st.session_state.tasks = {}

# 데이터 저장 함수
def save_tasks():
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(st.session_state.tasks, f, ensure_ascii=False, indent=2)

# 날짜 키 생성
def get_date_key(date):
    return date.strftime("%Y-%m-%d")

# 미완료 할 일 다음 날로 이동
def move_uncompleted_tasks():
    today = datetime.now().date()
    yesterday = today - timedelta(days=1)
    today_key = get_date_key(today)
    yesterday_key = get_date_key(yesterday)
    
    if yesterday_key in st.session_state.tasks:
        if today_key not in st.session_state.tasks:
            st.session_state.tasks[today_key] = []
        
        uncompleted = [t for t in st.session_state.tasks[yesterday_key] if not t.get('completed', False)]
        existing_texts = [t['text'].lower() for t in st.session_state.tasks[today_key]]
        
        for task in uncompleted:
            if task['text'].lower() not in existing_texts:
                new_task = task.copy()
                new_task['id'] = datetime.now().timestamp()
                st.session_state.tasks[today_key].append(new_task)
        
        st.session_state.tasks[yesterday_key] = [t for t in st.session_state.tasks[yesterday_key] if t.get('completed', False)]
        save_tasks()

# 앱 시작 시 미완료 할 일 이동
move_uncompleted_tasks()

# 헤더
weekdays = ['월', '화', '수', '목', '금', '토', '일']
current_date_str = st.session_state.current_date.strftime(f"%Y년 %m월 %d일 ({weekdays[st.session_state.current_date.weekday()]})")

col1, col2, col3 = st.columns([1, 3, 1])

with col1:
    if st.button("◀ 이전"):
        st.session_state.current_date -= timedelta(days=1)
        st.rerun()

with col2:
    st.markdown(f"<h1 style='text-align: center; color: #2563EB;'>{current_date_str}</h1>", unsafe_allow_html=True)

with col3:
    if st.button("다음 ▶"):
        st.session_state.current_date += timedelta(days=1)
        st.rerun()

if st.button("📅 오늘로 이동", use_container_width=True):
    st.session_state.current_date = datetime.now().date()
    st.rerun()

st.markdown("---")

# 사분면 정의
quadrants = {
    'urgent-important': {
        'title': '중요하고 긴급한 일',
        'desc': '오늘 반드시 처리해야 하는 일',
        'color': 'quadrant-1',
        'text_color': '#991B1B'
    },
    'not-urgent-important': {
        'title': '중요하지만 긴급하지 않은 일',
        'desc': '성장과 변화를 만드는 일',
        'color': 'quadrant-2',
        'text_color': '#14532D'
    },
    'urgent-not-important': {
        'title': '긴급하지만 중요하지 않은 일',
        'desc': '위임하거나 자동화할 수 있는 일',
        'color': 'quadrant-3',
        'text_color': '#854D0E'
    },
    'not-urgent-not-important': {
        'title': '중요하지도, 긴급하지도 않은 일',
        'desc': '과감히 줄이거나 없애야 하는 일',
        'color': 'quadrant-4',
        'text_color': '#1F2937'
    }
}

# 현재 날짜의 할 일 가져오기
date_key = get_date_key(st.session_state.current_date)
if date_key not in st.session_state.tasks:
    st.session_state.tasks[date_key] = []

# 2x2 그리드
row1_col1, row1_col2 = st.columns(2)
row2_col1, row2_col2 = st.columns(2)

cols = [row1_col1, row1_col2, row2_col1, row2_col2]
quadrant_keys = list(quadrants.keys())

for idx, (q_key, q_info) in enumerate(quadrants.items()):
    with cols[idx]:
        st.markdown(f"""
        <div class="quadrant-box {q_info['color']}">
            <h2 style="color: {q_info['text_color']}; margin-bottom: 0.25rem;">{q_info['title']}</h2>
            <p style="color: {q_info['text_color']}; font-size: 0.875rem; margin-bottom: 1rem;">{q_info['desc']}</p>
        </div>
        """, unsafe_allow_html=True)
        
        # 해당 사분면의 할 일 표시
        quadrant_tasks = [t for t in st.session_state.tasks[date_key] if t.get('quadrant') == q_key]
        
        for task in quadrant_tasks:
            task_id = task['id']
            
            col_check, col_text, col_edit, col_delete = st.columns([1, 6, 1, 1])
            
            with col_check:
                completed = st.checkbox(
                    "✓",
                    value=task.get('completed', False),
                    key=f"check_{date_key}_{task_id}",
                    label_visibility="collapsed"
                )
                if completed != task.get('completed', False):
                    for t in st.session_state.tasks[date_key]:
                        if t['id'] == task_id:
                            t['completed'] = completed
                    save_tasks()
                    st.rerun()
            
            with col_text:
                text_class = "task-completed" if task.get('completed', False) else ""
                st.markdown(f'<div class="task-item"><span class="{text_class}">{task["text"]}</span></div>', unsafe_allow_html=True)
            
            with col_edit:
                if st.button("✏️", key=f"edit_{date_key}_{task_id}"):
                    st.session_state[f'editing_{q_key}'] = task_id
                    st.session_state[f'edit_text_{q_key}'] = task['text']
                    st.rerun()
            
            with col_delete:
                if st.button("🗑️", key=f"delete_{date_key}_{task_id}"):
                    st.session_state.tasks[date_key] = [t for t in st.session_state.tasks[date_key] if t['id'] != task_id]
                    save_tasks()
                    st.rerun()
        
        # 수정 모드
        if f'editing_{q_key}' in st.session_state:
            edit_task_id = st.session_state[f'editing_{q_key}']
            edit_text = st.text_input(
                "할 일 수정",
                value=st.session_state.get(f'edit_text_{q_key}', ''),
                key=f'edit_input_{q_key}'
            )
            
            col_save, col_cancel = st.columns(2)
            with col_save:
                if st.button("💾 저장", key=f"save_{q_key}"):
                    if edit_text.strip():
                        for t in st.session_state.tasks[date_key]:
                            if t['id'] == edit_task_id:
                                t['text'] = edit_text.strip()
                        save_tasks()
                        del st.session_state[f'editing_{q_key}']
                        del st.session_state[f'edit_text_{q_key}']
                        st.rerun()
            
            with col_cancel:
                if st.button("❌ 취소", key=f"cancel_{q_key}"):
                    del st.session_state[f'editing_{q_key}']
                    del st.session_state[f'edit_text_{q_key}']
                    st.rerun()
        
        # 새 할 일 추가
        else:
            with st.expander("➕ 할 일 추가", expanded=False):
                new_task = st.text_input(
                    "새로운 할 일",
                    key=f"new_task_{q_key}",
                    placeholder="할 일을 입력하세요"
                )
                
                if st.button("추가하기", key=f"add_{q_key}"):
                    if new_task.strip():
                        st.session_state.tasks[date_key].append({
                            'id': datetime.now().timestamp(),
                            'text': new_task.strip(),
                            'quadrant': q_key,
                            'completed': False
                        })
                        save_tasks()
                        st.rerun()
