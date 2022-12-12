"""
Code that goes along with the Airflow located at:
http://airflow.readthedocs.org/en/latest/tutorial.html
"""
from airflow import DAG
# from airflow.operators.bash_operator import BashOperator
from airflow.operators.python_operator import PythonOperator, BranchPythonOperator
from datetime import datetime, timedelta
from airflow.models import Variable

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": datetime(2015, 6, 1),
    "email": ["airflow@airflow.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 0,
    "retry_delay": timedelta(seconds=2),
    "trigger_rule": "none_failed",
    # 'queue': 'bash_queue',
    # 'pool': 'backfill',
    # 'priority_weight': 10,
    # 'end_date': datetime(2016, 1, 1),
}

dag = DAG(
    dag_id="dz_6",
    default_args=default_args,
    # schedule_interval=timedelta(1),
    schedule_interval=None,
    catchup=False,)


def func_1(to_print, **kwargs):
    print(to_print)


def branch_operator(**kwargs):
    import random
    i = int(random.choice(list(eval(Variable.get('hw_etl')))))
    print(f'**********{i}**********')
    if i == 1:
        return ['task_2']
    elif i == 2:
        return ['task_3']
    else:
        return []


task_1 = BranchPythonOperator(
    task_id='task_1',
    python_callable=branch_operator,
    dag=dag,)

task_2 = PythonOperator(
    task_id='task_2',
    python_callable=func_1,
    op_kwargs={'to_print': 'TWO'},
    dag=dag,)

task_3 = PythonOperator(
    task_id='task_3',
    python_callable=func_1,
    op_kwargs={'to_print': 'THREE'},
    dag=dag,)

task_4 = PythonOperator(
    task_id='task_4',
    python_callable=func_1,
    op_kwargs={'to_print': 'FOUR'},
    dag=dag,)

task_5 = PythonOperator(
    task_id='task_5',
    python_callable=func_1,
    op_kwargs={'to_print': 'FIVE'},
    dag=dag,)

task_6 = PythonOperator(
    task_id='task_6',
    python_callable=func_1,
    op_kwargs={'to_print': 'SIX'},
    trigger_rule='all_done',
    dag=dag,)

task_1 >> [task_2, task_3, task_4]
task_3 >> task_5
task_4 >> task_5
task_2 >> task_6
task_5 >> task_6
